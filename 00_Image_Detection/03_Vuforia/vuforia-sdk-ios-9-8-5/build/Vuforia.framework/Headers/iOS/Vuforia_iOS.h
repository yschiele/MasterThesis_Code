/*===============================================================================
Copyright (c) 2019 PTC Inc. All Rights Reserved.

Copyright (c) 2010-2015 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other 
countries.

\file
    Vuforia_iOS.h

\brief
    Header file for global Vuforia methods that are specific to the iOS version.
===============================================================================*/

#ifndef _VUFORIA_VUFORIA_IOS_H_
#define _VUFORIA_VUFORIA_IOS_H_

namespace Vuforia
{

// iOS specific initialisation flags, numbered to avoid clashes with INIT_FLAGS.
enum IOS_INIT_FLAGS {
    ROTATE_IOS_90  = 128,  ///< <b>iOS:</b> Rotates rendering 90 degrees
    ROTATE_IOS_180 = 256,  ///< <b>iOS:</b> Rotates rendering 180 degrees
    ROTATE_IOS_270 = 512,  ///< <b>iOS:</b> Rotates rendering 270 degrees
    ROTATE_IOS_0   = 1024  ///< <b>iOS:</b> Rotates rendering 0 degrees
};

/// Set %Vuforia initialization parameters.
/**
 * <b>iOS:</b> Call this function before calling Vuforia::init().
 *
 * See the "Lifecycle of a Vuforia app" section on the main %Vuforia
 * reference page for more information. \ref Lifecycle "Lifecycle of a Vuforia app"
 *
 * \param flags Flags to set. See Vuforia::INIT_FLAGS and Vuforia::IOS_INIT_FLAGS
 * for appropriate flags.
 * \param licenseKey Your %Vuforia license key.
 *
 * \returns an integer result code: 0 for success, non-zero for failure (check
 * application logs for failure details).
 */
int VUFORIA_API setInitParameters(int flags, const char* licenseKey);

/// Set %Vuforia initialization parameters for Fusion provider available on iOS.
/**
 * \experimental
 * 
 * <b>iOS:</b> Call this function after Vuforia::init() and before getFusionProviders is called for the first time.
 *
 * This function is used to configure the ARKit session that will be used. An instance of the 
 * class ARWorldTrackingConfiguration should be created and its parameters should be
 * set as desired. The pointer to this instance should be passed in this function. 
 * Vuforia inspects the configuration values and takes a copy of the ones that are appropriate to use
 * with Vuforia. 
 *
 * Important to notice that the setting has no effect until \ref getFusionProviderPlatformInfo is called.
 * 
 * \note Be aware: Currently Vuforia makes use of only the AREnvironmentTexturing option, 
 * all other values are used based on Vuforia's usage of ARKit. 
 * The current configuration can be found using the function
 * \ref getFusionProviderPlatformInfo.
 * 
 * \param config Pointer to configuration to set. 
 *
 * \returns bool result code: true for success, false for failure
 */
bool VUFORIA_API setProviderConfiguration(const void * const config);

/// Set the current screen orientation.
/**
 * <b>iOS:</b> Call to set any rotation on the %Vuforia rendered video background
 * and augmentation projection matrices to compensate for your application's
 * auto-rotation behaviour.
 *
 * The value specified is used internally by %Vuforia to adapt rendering and
 * tracking to the current screen orientation.
 *
 * This method is used for integration of %Vuforia with Unity on iOS.
 *
 * See the sample apps for how to handle auto-rotation on non-Unity apps.
 *
 * \param rotation The rotation of the screen (one of Vuforia::IOS_INIT_FLAGS).
 */
void VUFORIA_API setRotation(int rotation);

} // namespace Vuforia

#endif //_VUFORIA_VUFORIA_IOS_H_
