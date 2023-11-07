import { useEffect } from 'react'
import { useDojoAccount, useDojoSystemCalls } from '../../DojoContext'
import { useGameplayContext, GameState } from '../hooks/GameplayContext'
import { useChamber, useChamberMap } from '../hooks/useChamber'
import { useKeyDown } from '../hooks/useKeyDown'
import { useUnderdarkContext } from '../hooks/UnderdarkContext'
import { Dir, FlippedDir, TileType } from '../utils/underdark'
import { bigintToHex, map } from '../utils/utils'
import { getLevelParams } from '../data/levels'
import GameCanvas from './GameCanvas'
import { AudioName } from '../data/assets'
import { useSettingsContext } from '../hooks/SettingsContext'


const GameView = ({
  // width = 620,
  // height = 350,
}) => {

  const { roomId, chamberId } = useUnderdarkContext()
  const { gameTilemap } = useChamberMap(chamberId)
  const { yonder } = useChamber(chamberId)
  const { gameImpl, isLoaded, isPlaying, hasLight, light, playerPosition, dispatchReset } = useGameplayContext()

  //
  // Start game!
  
  useEffect(() => {
    dispatchReset(gameTilemap?.playerStart ?? null, false)
  }, [gameTilemap, roomId, chamberId])

  useEffect(() => {
    gameImpl?.resetGameParams(getLevelParams(yonder).renderParams)
  }, [gameImpl, chamberId, yonder])

  useEffect(() => {
    gameImpl?.setGameParams({
      far: map(light, 0.0, 100.0, 1.6, 5.0),
      gamma: map(light, 0.0, 100.0, 2.0, 1.25),
    })
  }, [gameImpl, light])

  useEffect(() => {
    if (isLoaded || isPlaying) {
      gameImpl?.movePlayer(playerPosition)
    }
  }, [gameImpl, roomId, chamberId, playerPosition, isLoaded, isPlaying])

  useEffect(() => {
    if (isLoaded) {
      gameImpl?.setupMap(gameTilemap ?? null, false)
    }
  }, [gameImpl, gameTilemap, isLoaded])

  // game Start
  useEffect(() => {
    if (isPlaying) {
      gameImpl?.enableTilesByType(TileType.DarkTar, true)
    }
  }, [gameImpl, isPlaying])

  useEffect(() => {
    if (hasLight) {
      gameImpl?.enableTilesByType(TileType.Monster, isPlaying)
      gameImpl?.enableTilesByType(TileType.SlenderDuck, false)
    } else {
      gameImpl?.enableTilesByType(TileType.Monster, false)
      gameImpl?.enableTilesByType(TileType.SlenderDuck, isPlaying)
    }
  }, [gameImpl, isPlaying, hasLight])

  return (
    <div className='Relative GameView'>
      <GameCanvas guiEnabled={false} />
      <GameTriggers />
      <GameAudios />
      <GameControls />
    </div>
  )
}

const _isAround = (tilemap, tile, type) => {
  const x = tile % 16
  const y = Math.floor(tile / 16)
  if (x > 0 && tilemap[(x - 1) + (y) * 16] == type) return true
  if (x < 15 && tilemap[(x + 1) + (y) * 16] == type) return true
  if (y > 0 && tilemap[(x) + (y - 1) * 16] == type) return true
  if (y < 15 && tilemap[(x) + (y + 1) * 16] == type) return true
  return false
}

const GameTriggers = () => {
  const { chamberId } = useUnderdarkContext()
  const { tilemap } = useChamberMap(chamberId)
  const { sfxEnabled } = useSettingsContext()
  const {
    gameImpl, gameState, isPlaying, playerPosition, hasLight, health, stepCount, steps,
    dispatchGameState, dispatchMessage, dispatchHitDamage, dispatchNearDamage, dispatchDarkTar,
  } = useGameplayContext()

  useEffect(() => {
    if (!playerPosition || !isPlaying) return
    const { tile } = playerPosition
    // console.log(`Player at:`, tile, tilemap[tile])
    //
    // Reached door
    if (tilemap[tile] == TileType.DarkTar) {
      dispatchDarkTar(100)
      gameImpl?.playAudio(AudioName.DARK_TAR, sfxEnabled)
    } else if (tilemap[tile] == TileType.Monster) {
      dispatchHitDamage()
      gameImpl?.playAudio(AudioName.MONSTER_HIT, sfxEnabled)
    }
    else if (_isAround(tilemap, tile, TileType.Monster)) {
      dispatchNearDamage()
      gameImpl?.playAudio(AudioName.MONSTER_TOUCH, sfxEnabled)
    }
  }, [gameState, playerPosition?.tile])

  useEffect(() => {
    if (!playerPosition || !isPlaying) return
    const { tile, facing } = playerPosition
    if (tilemap[tile] == TileType.Exit && facing == Dir.South) {
      dispatchGameState(GameState.Verifying)
    }
  }, [gameState, playerPosition])

  useEffect(() => {
    if (isPlaying && !hasLight) {
      dispatchMessage('No light! Beware the Slender Duck!')
    }
  }, [gameState, hasLight])

  useEffect(() => {
    if (isPlaying && health == 0) {
      dispatchGameState(GameState.NoHealth)
    }
  }, [gameState, health])

  useEffect(() => {
    if (isPlaying && stepCount == 64) {
      dispatchGameState(GameState.Slendered)
    }
  }, [gameState, stepCount])


  //----------------------------------
  // Verify moves on-chain
  //
  const { finish_level } = useDojoSystemCalls()
  const { account } = useDojoAccount()
  useEffect(() => {
    if (gameState == GameState.Verifying) {
      let proof = 0n
      steps.map((step, index) => {
        proof |= (BigInt(step.dir) << BigInt(index * 4))
      });
      console.log(`PROOF:`, bigintToHex(proof))
      const success = finish_level(account, chamberId, proof, steps.length)
      if (success) {
        dispatchGameState(success ? GameState.Verified : GameState.NotVerified)
      }
    }
  }, [gameState])

  return  <></>
}


const GameAudios = () => {
  const { musicEnabled, sfxEnabled} = useSettingsContext()
  const { gameImpl, gameState, isPlaying, hasLight, playerPosition } = useGameplayContext()

  useEffect(() => {
    const _play = (isPlaying && hasLight && musicEnabled)
    gameImpl?.playAudio(AudioName.AMBIENT, _play)
  }, [isPlaying, hasLight, musicEnabled])

  useEffect(() => {
    const _play = (isPlaying && sfxEnabled)
    if (hasLight) {
      gameImpl?.playAudio(AudioName.TORCH, _play)
      gameImpl?.stopAudio(AudioName.SLENDER_DUCK)
    } else {
      gameImpl?.stopAudio(AudioName.TORCH)
      gameImpl?.playAudio(AudioName.EXTINGUISH, _play)
      gameImpl?.playAudio(AudioName.SLENDER_DUCK, _play)
    }
  }, [isPlaying, hasLight, sfxEnabled])

  useEffect(() => {
    if (isPlaying && sfxEnabled) {
      gameImpl?.playFootstep()
    }
  }, [playerPosition?.tile])

  useEffect(() => {
    if (gameState == GameState.Verifying) {
      gameImpl?.playAudio(AudioName.STAIRS, sfxEnabled)
    }
  }, [gameState])

  return <></>
}

//--------------------
// Keyboard controller
//
const GameControls = () => {
  const { chamberId } = useUnderdarkContext()
  const { tilemap } = useChamberMap(chamberId)
  const { isPlaying, playerPosition, dispatchMoveTo, dispatchTurnTo } = useGameplayContext()

  const directional = false
  useKeyDown(() => (directional ? _moveToDirection(Dir.East) : _rotate(1)), ['ArrowRight', 'd'])
  useKeyDown(() => (directional ? _moveToDirection(Dir.West) : _rotate(-1)), ['ArrowLeft', 'a'])
  useKeyDown(() => (directional ? _moveToDirection(Dir.North) : _move(1)), ['ArrowUp', 'w'])
  useKeyDown(() => (directional ? _moveToDirection(Dir.South) : _move(-1)), ['ArrowDown', 's'])

  const _moveToDirection = (dir) => {
    if (!isPlaying) return;
    dispatchMoveTo({ dir, tilemap })
    dispatchTurnTo(dir)
  }

  const _move = (signal) => {
    if (!isPlaying) return;
    const dir = signal < 0 ? FlippedDir[playerPosition.facing] : playerPosition.facing
    dispatchMoveTo({ dir, tilemap })
  }

  const _rotate = (signal) => {
    if (!isPlaying) return;
    const dir = (signal < 0 ? {
      [Dir.North]: Dir.West,
      [Dir.West]: Dir.South,
      [Dir.South]: Dir.East,
      [Dir.East]: Dir.North
    } : {
      [Dir.North]: Dir.East,
      [Dir.East]: Dir.South,
      [Dir.South]: Dir.West,
      [Dir.West]: Dir.North
    })[playerPosition.facing]
    dispatchTurnTo(dir)
  }

  return <></>
}

export default GameView
