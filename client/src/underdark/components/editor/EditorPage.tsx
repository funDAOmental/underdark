import { useState, useMemo, useEffect } from 'react'
import { MapColors } from '@/underdark/data/colors'
import { bigintToHex } from '@/underdark/utils/utils'

function EditorPage() {
  return (
    <div className="card">
      <EditorMap />
    </div>
  )
}

function EditorMap() {
  const [bitmap, setBitmap] = useState(BigInt('0xffffa8a8aeec82a0fbbfa209fbefe822effe80a0febe88aeeebfa83eafbee0e0'))
  const [activeTile, setActiveTile] = useState(-1)
  const activeBit = (255-activeTile)

  const tilemap = useMemo(() => {
    let result: number[] = []
    for (let i = 0; i < 256; ++i) {
      const bit = bitmap & (1n << BigInt(255 - i))
      result.push(bit ? 1 : 0)
    }
    return result
  }, [bitmap])
  useEffect(() => console.log(`EDITOR tilemap:`, bigintToHex(bitmap), tilemap), [tilemap])

  const _setTileBit = (index: number) => {
    setBitmap(bitmap ^ (1n << BigInt(255 - index)))
  }

  const _tileRect = (index: number) => {
    if (index < 0) return null
    const x = index % 16
    const y = Math.floor(index / 16)
    const bit = tilemap[index]
    const fill = bit ? MapColors.LOCKED : ((x + y) % 2 == 0) ? MapColors.BG2 : MapColors.BG3
    const stroke = activeTile == index ? '#fff' : MapColors.BG1
    return <rect
      key={`t_${index}`}
      x={x}
      y={y}
      width='1'
      height='1'
      fill={fill}
      stroke={stroke}
      strokeWidth={0.05}
      onMouseEnter={() => setActiveTile(index)}
      onMouseLeave={() => setActiveTile(-1)}
      onClick={() => _setTileBit(index)}
    />
  }

  const _clip = async () => BigInt(await navigator?.clipboard?.readText() ?? bitmap)

  return (
    <div className='AlignCenter'>
      <svg width='400' height='400' viewBox={`0 0 16 16`}>
        <style>{`svg{background-color:${MapColors.BG1}}`}</style>
        {/* @ts-ignore */}
        {tilemap.map((bit: number, index: number) => _tileRect(index))}
        {_tileRect(activeTile)}
      </svg>
      <p>
        Tile: [<b>{activeTile < 0 ? '-' : `${activeTile}/${bigintToHex(BigInt(activeTile))}`}</b>]
        X: [<b>{activeTile < 0 ? '-' : (activeTile % 16)}</b>]
        Y: [<b>{activeTile < 0 ? '-' : Math.floor(activeTile / 16)}</b>]
        Bit: [<b>{activeTile < 0 ? '-' : `${activeBit}/${bigintToHex(BigInt(activeBit))}`}</b >]
      </p>
      <p>
        {bigintToHex(bitmap)}
      </p>
      <p>
        <button onClick={() => setBitmap(0n)}>clear</button>
        &nbsp;
        <button onClick={() => setBitmap(bitmap ^ BigInt('0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'))}>invert</button>
        &nbsp;
        /
        &nbsp;
        <button onClick={() => { navigator?.clipboard?.writeText(bigintToHex(bitmap)) }}>copy</button>
        &nbsp;
        <button onClick={async () => { setBitmap(BigInt(await _clip())) }}>paste</button>
        &nbsp;
        <button onClick={async () => { setBitmap((bitmap & (BigInt('0xffffffffffffffffffffffffffffffff') << 128n)) | (await _clip())) }}>p_low</button>
        &nbsp;
        <button onClick={async () => { setBitmap((bitmap & BigInt('0xffffffffffffffffffffffffffffffff')) | ((await _clip()) << 128n)) }}>p_high</button>
        &nbsp;
        /
        &nbsp;
        <button onClick={() => { window.location.href = `/editor/playtest/?bitmap=${bigintToHex(bitmap) }` }}>playtest</button>
      </p>
    </div>
  )
}



export default EditorPage
