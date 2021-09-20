/**
 * Copyright (c) 2017-present, Viro Media, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';

import {
  ViroARScene,
  ViroImage,
  ViroQuad,
  ViroNode,
  ViroMaterials,
  ViroOmniLight,
  ViroARTrackingTargets,
  ViroARImageMarker,
  ViroAnimations,
  Viro3DObject,
  ViroSpotLight,
  ViroAmbientLight,
  ViroParticleEmitter,
  ViroSphere,
  ViroText,
} from 'react-viro';

var createReactClass = require('create-react-class');

var ARPosterDemo = createReactClass({
  getInitialState: function() {
    return {
      loopState:false,
      animationName:"01",
      pauseUpdates : false,
      playAnim: false,
      modelAnim: false,
    };
  },

  render() {
    return (

      <ViroARScene>
        <ViroAmbientLight color="#ffffff" intensity={200}/>
        <ViroARImageMarker target={"poster"} onAnchorFound={this._onAnchorFound} onAnchorRemoved={this._onAnchorRemoved} pauseUpdates={this.state.pauseUpdates}/>
        
        <ViroOmniLight
            intensity={300}
            position={[-10, 10, 1]}
            color={"#FFFFFF"}
            attenuationStartDistance={20}
            attenuationEndDistance={30} />

        <ViroOmniLight
            intensity={300}
            position={[10, 10, 1]}
            color={"#FFFFFF"}
            attenuationStartDistance={20}
            attenuationEndDistance={30} />

        <ViroOmniLight
            intensity={300}
            position={[-10, -10, 1]}
            color={"#FFFFFF"}
            attenuationStartDistance={20}
            attenuationEndDistance={30} />

        <ViroOmniLight
            intensity={300}
            position={[10, -10, 1]}
            color={"#FFFFFF"}
            attenuationStartDistance={20}
            attenuationEndDistance={30} />

        <ViroSpotLight
          position={[0, 8, -2]}
          color="#ffffff"
          direction={[0, -1, 0]}
          intensity={50}
          attenuationStartDistance={5}
          attenuationEndDistance={10}
          innerAngle={5}
          outerAngle={20}
          castsShadow={true}
        />

        <ViroQuad
          rotation={[-90, 0, 0]}
          position={[0, -1.6, 0]}
          width={5} height={5}
          arShadowReceiver={true}
          />

      </ViroARScene>
    );
  },

  _onAnchorFound() {
    this.props.sceneNavigator.viroAppProps(true);
  },

  _onAnchorRemoved() {
    console.debug("_onAnchorRemoved");
    this.props.sceneNavigator.viroAppProps(false);
  },
});

var styles = StyleSheet.create({
  helloWorldTextStyle: {
    fontFamily: 'Arial',
    fontSize: 30,
    color: '#ffffff',
    textAlignVertical: 'center',
    textAlign: 'center',
  },
});

ViroARTrackingTargets.createTargets({
  poster : {
    source : require('./res/puppy.jpg'),
    orientation : "Up",
    physicalWidth : 0.4 // real world width in meters
  }
});

module.exports = ARPosterDemo;
