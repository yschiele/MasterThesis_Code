/**
 * Copyright (c) 2015-present, Viro Media, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 */
'use strict';

import React, { Component } from 'react';

import {
  AppRegistry,
  StyleSheet,
  Dimensions,
  Text,
  View
} from 'react-native';

import {
  ViroVRSceneNavigator,
  ViroARSceneNavigator,
} from 'react-viro';

var createReactClass = require('create-react-class');
var arScenes = {
  'ARPosterDemo' : require('./js/ARPosterDemo/ARPosterDemo.js'),
  'ARSample' : require('./js/ARSample/HelloWorldSceneAR.js')
}

export default class ViroCodeSamplesSceneNavigator extends Component {
  
  constructor() {
    super();
    this._changeText = this._changeText.bind(this);
    this.state = {
      imageDetected: false,
    }
  }

  render() {
    return (
      <View style={{ flex: 1 }}>
        <ViroARSceneNavigator
          initialScene={{
            scene: arScenes['ARPosterDemo'],
          }}
          viroAppProps={this._changeText}/>
          <View style={styles.crosshair}> 
          {this._renderTrackingText()}
          </View>
      </View>);
    }

_renderTrackingText() {
  if(this.state.imageDetected) {
    return (<Text style={styles.detectedText}>Image detected!</Text>);
  } else {
    return (<Text style={styles.undetectedText}>Searching for Image</Text>);
  }
 }

_changeText(value) {
          this.setState({
            imageDetected: value
          });
 }
}

var styles = StyleSheet.create({
  undetectedText: {
    fontFamily: 'Arial',
    fontSize: 20,
    color: 'darkgrey',
    textAlignVertical: 'center',
    textAlign: 'left',
    marginLeft: 10,
  },
  detectedText: {
    fontFamily: 'Arial',
    fontSize: 24,
    color: 'red',
    textAlignVertical: 'center',
    textAlign: 'left',
    marginLeft: 10,
  },
  crosshair: {
    position: 'absolute',
    top: 75,
    left: 25,
    width: 250,
    height: 70,
    borderRadius: 15,
    borderWidth: 1,
    backgroundColor: 'white',
    opacity: 0.7,
    borderColor: 'white',
    justifyContent: 'center',
},
});

module.exports = ViroCodeSamplesSceneNavigator;
