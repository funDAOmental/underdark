import { useSyncWorld } from '../hooks/useGraphQLQueries'
import { UnderdarkProvider } from '../hooks/UnderdarkContext'
import { GameplayProvider } from '../hooks/GameplayContext'
import GameView from './GameView'
import GameUI from './GameUI'

function Underdark() {
  const { loading } = useSyncWorld()

  if (loading) {
    return <h1>loading...</h1>
  }

  return (
    <UnderdarkProvider>
      <GameplayProvider>
        <div>

          <GameUI />
          
          <br />
          
          <GameView />

        </div>
      </GameplayProvider>
    </UnderdarkProvider>
  )
}

export default Underdark
