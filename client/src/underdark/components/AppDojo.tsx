import React, { useMemo, useState } from 'react'
import { useEffectOnce } from '@/underdark/hooks/useEffectOnce'
import { DojoConfig, createDojoConfig } from '@dojoengine/core'
import { DojoProvider } from '@/dojo/DojoContext'
import { setup } from '@/dojo/setup'
import { GameplayProvider } from '@/underdark/hooks/GameplayContext'
import { DojoStatus } from '@/underdark/components/DojoStatus'
import App from '@/underdark/components/App'
import manifest from '../../manifest.json'

export default function AppDojo({
  title = null,
  backgroundImage = null,
  children,
}) {
  return (
    <App title={title} backgroundImage={backgroundImage}>
      <DojoSetup>
        {children}
      </DojoSetup>
    </App>
  );
}

function DojoSetup({ children }) {
  const [setupResult, setSetupResult] = useState(null)

  const config: DojoConfig = useMemo(() => {
    if (!process.env.NEXT_PUBLIC_NODE_URL) throw (`NEXT_PUBLIC_NODE_URL is null`)
    if (!process.env.NEXT_PUBLIC_TORII) throw (`NEXT_PUBLIC_TORII is null`)
    if (!process.env.NEXT_PUBLIC_MASTER_ADDRESS) throw (`NEXT_PUBLIC_MASTER_ADDRESS is not set`)
    if (!process.env.NEXT_PUBLIC_MASTER_PRIVATE_KEY) throw (`NEXT_PUBLIC_MASTER_PRIVATE_KEY is not set`)
    const result = {
      ...createDojoConfig({ manifest }),
      rpcUrl: process.env.NEXT_PUBLIC_NODE_URL,
      toriiUrl: process.env.NEXT_PUBLIC_TORII,
      masterAddress: process.env.NEXT_PUBLIC_MASTER_ADDRESS,
      masterPrivateKey: process.env.NEXT_PUBLIC_MASTER_PRIVATE_KEY,
    }
    return result
  }, [])

  useEffectOnce(() => {
    let _mounted = true
    const _setup = async () => {
      console.log(`DojoConfig:`, config)
      const result = await setup(config)
      if (_mounted) {
        setSetupResult(result)
      }
    }
    _setup()
    return () => {
      _mounted = false
    }
  }, [])

  if (!setupResult) {
    return (
      <>
        <h1 className='TitleCase'>Loading Up...</h1>
        <h5><DojoStatus /></h5>
      </>
    )
  }

  return (
    <DojoProvider value={setupResult}>
      <GameplayProvider>
        {children}
      </GameplayProvider>
    </DojoProvider>
  );
}
