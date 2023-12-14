import * as THREE from 'three'
//@ts-ignore
import { FBXLoader } from 'three/addons/loaders/FBXLoader.js'

const HALF_PI = Math.PI * 0.5


//----------------------------
// Model Assets
//
enum ModelName {
  MONSTER = 'MONSTER',
  SLENDER_DUCK = 'SLENDER_DUCK',
  DARK_TAR = 'DARK_TAR',
  DOOR = 'DOOR',
  STAIRS = 'STAIRS',
  CHEST = 'CHEST',
}

interface ModelAsset {
  path: string
  scale: number
  rotation: number[]
  object?: any
}
type ModelAssets = {
  [key in ModelName]: ModelAsset
}

let MODELS_ASSETS: ModelAssets = {
  MONSTER: {
    path: '/models/duck3.ok.fbx',
    scale: 0.005,
    rotation: [HALF_PI, 0, 0],
  },
  SLENDER_DUCK: {
    path: '/models/slendie.ok.fbx',
    scale: 0.005,
    rotation: [HALF_PI, 0, 0],
  },
  DARK_TAR: {
    path: '/models/tar.ok.fbx',
    scale: 0.005,
    rotation: [HALF_PI, 0, 0],
  },
  DOOR: {
    path: '/models/door.fbx',
    scale: 0.005,
    rotation: [HALF_PI, HALF_PI, 0],
  },
  STAIRS: {
    path: '/models/stairs.ok.fbx',
    scale: 0.005,
    rotation: [HALF_PI, HALF_PI, 0],
  },
  CHEST: {
    path: '/models/chest.ok.fbx',
    scale: 0.005,
    rotation: [HALF_PI, 0, 0],
  },
}


//----------------------------
// Audio Assets
//
enum AudioName {
  AMBIENT = 'AMBIENT',
  SLENDER_DUCK = 'SLENDER_DUCK',
  TORCH = 'TORCH',
  EXTINGUISH = 'EXTINGUISH',
  DARK_TAR = 'DARK_TAR',
  STAIRS = 'STAIRS',
  CHEST = 'CHEST',
  FOOT1 = 'FOOT1',
  FOOT2 = 'FOOT2',
  MONSTER_NEAR = 'MONSTER_NEAR',
  MONSTER_TOUCH = 'MONSTER_TOUCH',
  MONSTER_HIT = 'MONSTER_HIT',
}

interface AudioAsset {
  path: string
  loop?: boolean
  volume?: number
  object?: any
  loaded?: boolean
}
type AudioAssets = {
  [key in AudioName]: AudioAsset
}


let AUDIO_ASSETS: AudioAssets = {
  AMBIENT: {
    path: '/audio/music-ambient.m4a',
    volume: 0.5,
    loop: true,
  },
  SLENDER_DUCK: {
    path: '/audio/sfx/slenderduck.m4a',
    loop: true,
  },
  TORCH: {
    path: '/audio/sfx/torch.m4a',
    loop: true,
  },
  EXTINGUISH: {
    path: '/audio/sfx/extinguish.m4a',
    loop: false,
  },
  DARK_TAR: {
    path: '/audio/sfx/darktar.m4a',
    loop: false,
  },
  STAIRS: {
    path: '/audio/sfx/stairs.m4a',
    loop: false,
  },
  CHEST: {
    path: '/audio/sfx/chest.m4a',
    loop: false,
  },
  FOOT1: {
    path: '/audio/sfx/foot1.m4a',
    loop: false,
  },
  FOOT2: {
    path: '/audio/sfx/foot2.m4a',
    loop: false,
  },
  MONSTER_NEAR: {
    path: '/audio/sfx/monster_near.m4a',
    loop: false,
  },
  MONSTER_TOUCH: {
    path: '/audio/sfx/monster_touch.m4a',
    loop: false,
  },
  MONSTER_HIT: {
    path: '/audio/sfx/monster_hit.m4a',
    loop: false,
  },
}



//----------------------------
// Loaders
//
// Generic loader
const _loader = async (ASSETS, onLoading) => {
  return new Promise<void>((resolve, reject) => {
    let assetsToLoad = Object.keys(ASSETS).length
    Object.keys(ASSETS).forEach((name) => {
      onLoading(name, (object) => {
        ASSETS[name].object = object
        if (--assetsToLoad == 0) {
          resolve()
        }
      })
    })
  })
}

//-----------------
// Models
//
const _loadModels = async () => {
  const loader = new FBXLoader()
  return _loader(MODELS_ASSETS, (name, resolve) => {
    const asset = MODELS_ASSETS[name]
    loader.load(asset.path, function (object) {
      // load asset...
      // console.log(`CACHED MODEL [${name}]:`, object, object?.scale)
      if (object) {
        if (asset.rotation) object.rotation.set(asset.rotation[0], asset.rotation[1], asset.rotation[2])
        if (asset.scale) object.scale.set(asset.scale, asset.scale, asset.scale)
      }
      resolve(object ?? null)
    })
  })
}

//-----------------
// Audios
//
const _loadAudios = async (listener) => {
  const loader = new THREE.AudioLoader()
  return _loader(AUDIO_ASSETS, (name, resolve) => {
    const asset = AUDIO_ASSETS[name]
    try {
      loader.load(asset.path, function (buffer) {
        // load asset...
        let audio = null
        // console.log(`CACHED AUDIO [${name}]:`, buffer)
        if (buffer) {
          audio = new THREE.Audio(listener).setBuffer(buffer)
          audio.setLoop(asset.loop ?? false)
          audio.setVolume(asset.volume ?? 1.0)
          audio.autoplay = false
        }
        resolve(audio)
      })
      } catch(e) {
        console.error(`CACHED AUDIO [${name}] FAILED!`, e)
    }
  })
}



//----------------------------
// Main Asset Loader
//
// assets that can be loaded when the page loads
let _loadingAssets: boolean
const loadAssets = async () => {
  if (_loadingAssets === undefined) {
    _loadingAssets = true
    await _loadModels()
    console.log(`--- CACHED MODELS! 👍`)
    _loadingAssets = false
  }
  return _loadingAssets
}
//
// Audios need to be loaded after user interaction
// call this from some button
let _audioAssetsLoaded: boolean
const loadAudioAssets = async (cameraRig: any) => {
  if (_audioAssetsLoaded === undefined) {
    _audioAssetsLoaded = false
    const listener = new THREE.AudioListener()
    cameraRig.add(listener)
    await _loadAudios(listener)
    console.log(`--- CACHED AUDIOS! 👍`)
    _audioAssetsLoaded = true
  }
  return _audioAssetsLoaded
}
const isAudioAssetsLoaded = () => {
  return _audioAssetsLoaded
}


export {
  loadAssets,
  loadAudioAssets,
  isAudioAssetsLoaded,
  ModelName,
  AudioName,
  MODELS_ASSETS,
  AUDIO_ASSETS
}
