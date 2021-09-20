/*===============================================================================
Copyright (c) 2020, PTC Inc. All rights reserved.

Vuforia is a trademark of PTC Inc., registered in the United States and other
countries.
===============================================================================*/

import UIKit
import MetalKit


/// Class to encapsulate Metal rendering for the sample
class MetalRenderer {

    private var mMetalDevice:MTLDevice

    
    
    private var mVideoBackgroundPipelineState:MTLRenderPipelineState!
    private var mAxisPipelineState:MTLRenderPipelineState!
    private var mUniformColorShaderPipelineState:MTLRenderPipelineState!
    private var mTexturedVertexShaderPipelineState:MTLRenderPipelineState!

    private var mDefaultSamplerState:MTLSamplerState?
    private var mWrappingSamplerState:MTLSamplerState?

    private var mVideoBackgroundVertices:MTLBuffer!
    private var mVideoBackgroundIndices:MTLBuffer!
    private var mVideoBackgroundTextureCoordinates:MTLBuffer!

    private var mCubeVertices:MTLBuffer!
    private var mCubeIndices:MTLBuffer!
    private var mCubeWireframeIndices:MTLBuffer!

    private var mSquareVertices:MTLBuffer!
    private var mSquareIndices:MTLBuffer!
    private var mSquareWireframeIndices:MTLBuffer!
    private var mSquareTextureCoordinates:MTLBuffer!

    private var mAxisVertices:MTLBuffer!
    private var mAxisIndices:MTLBuffer!
    private var mAxisColors:MTLBuffer!

    // Buffers for world origin model-view-projection matrices
    private var mWorldOriginAxisMVP:MTLBuffer!
    private var mWorldOriginCubeMVP:MTLBuffer!

    // Buffers for augmentation model-view-projection matrices
    private var mAugmentationMVP:MTLBuffer!
    private var mAugmentationAxisMVP:MTLBuffer!
    private var mAugmentationScaledMVP:MTLBuffer!

    // The guide view image data from AppController
    private var mGuideViewBuffer:MTLBuffer!
    // The texture for rendering the Guide View
    private var mGuideViewTexture:MTLTexture!

    private let colorRed = vector_float4(Float(1), Float(0), Float(0), Float(1))
    private let colorGrey = vector_float4(Float(0.8), Float(0.8), Float(0.8), Float(1.0))

    

    /// Initialize the renderer ready for use
    init(metalDevice: MTLDevice, layer: CAMetalLayer, library: MTLLibrary?, textureDepth: MTLTexture) {
        mMetalDevice = metalDevice
        
        let stateDescriptor = MTLRenderPipelineDescriptor()

        //
        // Video background
        //
        
        stateDescriptor.vertexFunction = library?.makeFunction(name: "texturedVertex")
        stateDescriptor.fragmentFunction = library?.makeFunction(name: "texturedFragment")
        stateDescriptor.colorAttachments[0].pixelFormat = layer.pixelFormat
        stateDescriptor.depthAttachmentPixelFormat = textureDepth.pixelFormat
        
        // And create the pipeline state with the descriptor
        do {
            try self.mVideoBackgroundPipelineState = metalDevice.makeRenderPipelineState(descriptor: stateDescriptor)
        } catch {
            print("Failed to create video background render pipeline state:",error)
        }
        
        //
        // Augmentations
        //

        // Create pipeline for world origin
        stateDescriptor.vertexFunction = library?.makeFunction(name: "vertexColorVertex")
        stateDescriptor.fragmentFunction = library?.makeFunction(name: "vertexColorFragment")
        stateDescriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
        stateDescriptor.depthAttachmentPixelFormat = textureDepth.pixelFormat
        do {
            try self.mAxisPipelineState = metalDevice.makeRenderPipelineState(descriptor: stateDescriptor)
        } catch {
            print("Failed to create axis render pipeline state:",error)
            return
        }

        // Create pipeline for transparent object overlays
        stateDescriptor.vertexFunction = library?.makeFunction(name: "uniformColorVertex")
        stateDescriptor.fragmentFunction = library?.makeFunction(name: "uniformColorFragment")
        stateDescriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;
        stateDescriptor.colorAttachments[0].isBlendingEnabled = true
        stateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add
        stateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add
        stateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.sourceAlpha
        stateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.sourceAlpha
        stateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        stateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha
        stateDescriptor.depthAttachmentPixelFormat = textureDepth.pixelFormat
        do {
            try self.mUniformColorShaderPipelineState = metalDevice.makeRenderPipelineState(descriptor: stateDescriptor)
        } catch {
            print("Failed to create augmentation render pipeline state:",error)
            return
        }

        stateDescriptor.vertexFunction = library?.makeFunction(name: "texturedVertex")
        stateDescriptor.fragmentFunction = library?.makeFunction(name: "texturedFragment")
        
        // Create pipeline for rendering textures
        do {
            try self.mTexturedVertexShaderPipelineState = metalDevice.makeRenderPipelineState(descriptor: stateDescriptor)
        } catch {
            print("Failed to create guide view render pipeline state:", error)
            return
        }

        mDefaultSamplerState = MetalRenderer.defaultSampler(device: metalDevice)
        mWrappingSamplerState = MetalRenderer.wrappingSampler(device: metalDevice)
        
        // Allocate space for rendering data for Video background
        mVideoBackgroundVertices = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 3 * 4, options: [])
        mVideoBackgroundTextureCoordinates = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 2 * 4, options: [])
        mVideoBackgroundIndices = mMetalDevice.makeBuffer(length: MemoryLayout<UInt16>.size * 6, options: [])

        // Load rendering data for cube
        mCubeVertices = metalDevice.makeBuffer(bytes: Models.cubeVertices, length: MemoryLayout<Float>.size * 3 * Int(Models.NUM_CUBE_VERTEX), options: [])
        mCubeIndices = metalDevice.makeBuffer(bytes: Models.cubeIndices, length: MemoryLayout<UInt16>.size * Int(Models.NUM_CUBE_INDEX), options: [])
        mCubeWireframeIndices
            = metalDevice.makeBuffer(bytes: Models.cubeWireframeIndices, length: MemoryLayout<UInt16>.size * Int(Models.NUM_CUBE_WIREFRAME_INDEX), options: [])

        // Load rendering data for square
        mSquareVertices = metalDevice.makeBuffer(bytes: Models.squareVertices, length: MemoryLayout<Float>.size * 3 * Int(Models.NUM_SQUARE_VERTEX), options: [])
        mSquareIndices = metalDevice.makeBuffer(bytes: Models.squareIndices, length: MemoryLayout<UInt16>.size * Int(Models.NUM_SQUARE_INDEX), options: [])
        mSquareWireframeIndices
            = metalDevice.makeBuffer(bytes: Models.squareWireframeIndices, length: MemoryLayout<UInt16>.size * Int(Models.NUM_SQUARE_WIREFRAME_INDEX), options: [])
        mSquareTextureCoordinates = metalDevice.makeBuffer(bytes: Models.squareTexCoords, length: MemoryLayout<Float>.size * 8, options: [])

        // Load rendering data for axes
        mAxisVertices = metalDevice.makeBuffer(bytes: Models.axisVertices, length: MemoryLayout<Float>.size * 3 * Int(Models.NUM_AXIS_VERTEX), options:[])
        mAxisIndices = metalDevice.makeBuffer(bytes: Models.axisIndices, length: MemoryLayout<UInt16>.size * Int(Models.NUM_AXIS_INDEX), options: [])
        mAxisColors = metalDevice.makeBuffer(bytes: Models.axisColors, length: MemoryLayout<Float>.size * 4 * Int(Models.NUM_AXIS_COLOR), options:[])

        mWorldOriginAxisMVP = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16)
        mWorldOriginCubeMVP = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16)
        mAugmentationMVP = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16)
        mAugmentationAxisMVP = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16)
        mAugmentationScaledMVP = mMetalDevice.makeBuffer(length: MemoryLayout<Float>.size * 16)
    }


    /// Render the video background
    func renderVideoBackground(encoder: MTLRenderCommandEncoder?, projectionMatrix: MTLBuffer, mesh: VuforiaMesh) {

        // Copy mesh data into metal buffers
        mVideoBackgroundVertices.contents().copyMemory(from: mesh.vertices, byteCount: MemoryLayout<Float>.size * Int(mesh.numVertices) * 3)
        mVideoBackgroundTextureCoordinates.contents().copyMemory(from: mesh.textureCoordinates, byteCount: MemoryLayout<Float>.size * Int(mesh.numVertices) * 2)
        mVideoBackgroundIndices.contents().copyMemory(from: mesh.indices, byteCount: MemoryLayout<CShort>.size * Int(mesh.numIndices))
        
        // Set the render pipeline state
        encoder?.setRenderPipelineState(mVideoBackgroundPipelineState)
        
        // Set the texture coordinate buffer
        encoder?.setVertexBuffer(mVideoBackgroundTextureCoordinates, offset: 0, index: 2)
        
        // Set the vertex buffer
        encoder?.setVertexBuffer(mVideoBackgroundVertices, offset: 0, index: 0)
        
        // Set the projection matrix
        encoder?.setVertexBuffer(projectionMatrix, offset: 0, index: 1)
       
        encoder?.setFragmentSamplerState(mDefaultSamplerState, index: 0)

        // Draw the geometry
        encoder?.drawIndexedPrimitives(type: MTLPrimitiveType.triangle,indexCount: 6, indexType: .uint16, indexBuffer: mVideoBackgroundIndices, indexBufferOffset: 0)
    }

    
    /// Render a bounding box augmentation on an Image Target
    func renderImageTarget(encoder: MTLRenderCommandEncoder?,
                           projectionMatrix: matrix_float4x4,
                           modelViewMatrix: matrix_float4x4, scaledModelViewMatrix: matrix_float4x4) {
        
        var modelViewProjection = projectionMatrix * modelViewMatrix
        mAugmentationMVP.contents().copyMemory(from: &modelViewProjection.columns, byteCount: MemoryLayout<Float>.size * 16)
        var scaledModelViewProjectionMatrix = projectionMatrix * scaledModelViewMatrix
        mAugmentationScaledMVP.contents().copyMemory(from: &scaledModelViewProjectionMatrix.columns, byteCount: MemoryLayout<Float>.size * 16)

        // Draw translucent bounding box overlay
        encoder?.setRenderPipelineState(mUniformColorShaderPipelineState)

        encoder?.setVertexBuffer(mSquareVertices, offset: 0, index: 0)
        encoder?.setVertexBuffer(mAugmentationScaledMVP, offset: 0, index: 1)

        var color = colorRed
        // Draw translucent square
        color[3] = 0.2
        encoder?.setFragmentBytes(&color, length: MemoryLayout.size(ofValue: color), index: 0)
        encoder?.drawIndexedPrimitives(type: .triangle, indexCount: Int(Models.NUM_SQUARE_INDEX), indexType: .uint16, indexBuffer: mSquareIndices, indexBufferOffset: 0)
        // Draw solid wireframe
        color[3] = 1.0
        encoder?.setFragmentBytes(&color, length: MemoryLayout.size(ofValue: color), index: 0)
        encoder?.drawIndexedPrimitives(type: .line, indexCount: Int(Models.NUM_SQUARE_WIREFRAME_INDEX), indexType: .uint16, indexBuffer: mSquareWireframeIndices, indexBufferOffset: 0)
        
        // Draw an axis
        renderAxis(encoder: encoder, mvpBuffer: mAugmentationAxisMVP,
                 projectionMatrix: projectionMatrix, modelViewMatrix: modelViewMatrix, scale: vector_float3(0.02, 0.02, 0.02))
    }


    
    /// Render the Guide View for a model target
    func renderModelTargetGuideView(encoder: MTLRenderCommandEncoder?,
                                    modelViewProjectionMatrix: MTLBuffer,
                                    guideViewImage: inout VuforiaImage) {

        if (mGuideViewTexture == nil || mGuideViewBuffer == nil) {
            // We only have a single Guide View in this app so we load the texture once now
            
            // Setup texture for Guide View
            let textureDescriptor = MTLTextureDescriptor.init()
            textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm;
            textureDescriptor.width = Int(guideViewImage.width);
            textureDescriptor.height = Int(guideViewImage.height);
            mGuideViewTexture = mMetalDevice.makeTexture(descriptor: textureDescriptor);
            
            let bufferSize = Int(guideViewImage.height * guideViewImage.stride)
            mGuideViewBuffer = mMetalDevice.makeBuffer(length: bufferSize, options: [])
            if (getImagePixels(&guideViewImage, mGuideViewBuffer.contents(), Int32(bufferSize))) {
                let data = NSData(bytes: mGuideViewBuffer.contents(), length: bufferSize)
                let region = MTLRegion.init(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: Int(guideViewImage.width), height: Int(guideViewImage.height), depth: 1))
                mGuideViewTexture.replace(region: region, mipmapLevel: 0, withBytes: data.bytes, bytesPerRow: Int(guideViewImage.stride))
            } else {
                print("ERROR: Failed to read Guide View pixels")
                mGuideViewTexture = nil;
            }
        }

        encoder?.setRenderPipelineState(mTexturedVertexShaderPipelineState)
        encoder?.setFragmentTexture(mGuideViewTexture, index: 0)
        encoder?.setVertexBuffer(mSquareTextureCoordinates, offset: 0, index: 2)
        encoder?.setVertexBuffer(mSquareVertices, offset: 0, index: 0)
        encoder?.setVertexBuffer(modelViewProjectionMatrix, offset: 0, index: 1)
        encoder?.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: mSquareIndices, indexBufferOffset: 0)
    
    }
    
    
    private func renderAxis(encoder: MTLRenderCommandEncoder?, mvpBuffer: MTLBuffer,
                          projectionMatrix: matrix_float4x4, modelViewMatrix: matrix_float4x4, scale: vector_float3) {
        // Scale the model view for axis rendering and update MVP
        let modelViewMatrixScaled = modelViewMatrix * matrix_float4x4(diagonal: SIMD4<Float>(scale.x, scale.y, scale.z, 1.0))
        var modelViewProjectionMatrix = projectionMatrix * modelViewMatrixScaled
        mvpBuffer.contents().copyMemory(from: &modelViewProjectionMatrix.columns, byteCount: MemoryLayout<Float>.size * 16)
        
        encoder?.setRenderPipelineState(mAxisPipelineState)
        encoder?.setVertexBuffer(mAxisVertices, offset: 0, index: 0)
        encoder?.setVertexBuffer(mAxisColors, offset: 0, index: 1)
        encoder?.setVertexBuffer(mvpBuffer, offset: 0, index: 2)
        encoder?.drawIndexedPrimitives(type: .line, indexCount: 6, indexType: .uint16, indexBuffer: mAxisIndices, indexBufferOffset: 0)
    }

    
    private func renderModel(encoder: MTLRenderCommandEncoder?,
                             vertices: MTLBuffer, vertexCount: Int,
                             textureCoordinates: MTLBuffer, texture: MTLTexture,
                             mvpBuffer: MTLBuffer) {

        encoder?.setRenderPipelineState(mTexturedVertexShaderPipelineState)
        encoder?.setFragmentTexture(texture, index: 0)
        encoder?.setFragmentSamplerState(mWrappingSamplerState, index: 0)
        encoder?.setVertexBuffer(textureCoordinates, offset: 0, index: 2)
        encoder?.setVertexBuffer(vertices, offset: 0, index: 0)
        encoder?.setVertexBuffer(mvpBuffer, offset: 0, index: 1)
        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
    
    
    class func defaultSampler(device: MTLDevice) -> MTLSamplerState? {
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter             = MTLSamplerMinMagFilter.linear
        sampler.magFilter             = MTLSamplerMinMagFilter.linear
        sampler.mipFilter             = MTLSamplerMipFilter.linear
        sampler.maxAnisotropy         = 1
        sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.rAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.normalizedCoordinates = true
        sampler.lodMinClamp           = 0
        sampler.lodMaxClamp           = .greatestFiniteMagnitude
        return device.makeSamplerState(descriptor: sampler)
    }


    class func wrappingSampler(device: MTLDevice) -> MTLSamplerState? {
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter             = MTLSamplerMinMagFilter.nearest
        sampler.magFilter             = MTLSamplerMinMagFilter.nearest
        sampler.mipFilter             = MTLSamplerMipFilter.nearest
        sampler.maxAnisotropy         = 1
        sampler.sAddressMode          = MTLSamplerAddressMode.repeat
        sampler.tAddressMode          = MTLSamplerAddressMode.repeat
        sampler.rAddressMode          = MTLSamplerAddressMode.repeat
        sampler.normalizedCoordinates = true
        sampler.lodMinClamp           = 0
        sampler.lodMaxClamp           = .greatestFiniteMagnitude
        return device.makeSamplerState(descriptor: sampler)
    }
}
