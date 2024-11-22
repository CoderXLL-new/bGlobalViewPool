/*
 * Copyright (2024) Bytedance Ltd. and/or its affiliates
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { BuilderNode, FrameNode, NodeController } from '@kit.ArkUI'
import { ViewNodePool } from './ViewNodePool'
import { ViewPoolManager } from '../ViewPoolManager';
import { ViewNodeEnvCallback } from './ViewNodeEnvCallback';

export class ViewNodeCtrlImpl extends NodeController {
  TAG: string = "ViewNodeCtrlImpl"
  private mBuildNode: BuilderNode<ESObject> | null = null
  private environmentCallbackId?: number
  public wrapperBuilder: WrappedBuilder<ESObject>
  public data: ESObject
  public type: string
  public id: number
  public isFirstRender: boolean = true

  constructor(builder: WrappedBuilder<ESObject>, data: ESObject, type: string) {
    super()
    this.wrapperBuilder = builder
    this.data = data
    this.type = type
    this.id = ViewNodePool.getInstance().getNextIdByType(type)
  }

  public registerEnvCallback() {
    this.environmentCallbackId = ViewPoolManager.getInstance().getContext()?.getApplicationContext().on("environment", new ViewNodeEnvCallback(()=>{
      this.mBuildNode?.updateConfiguration()
    }))
  }

  public unRegisterEnvCallback() {
    if (this.environmentCallbackId) {
      ViewPoolManager.getInstance().getContext()?.getApplicationContext().off("environment", this.environmentCallbackId)
    }
  }

  getBuildNode(): BuilderNode<ESObject> | null{
    return this.mBuildNode
  }

  recycle() {
    this.mBuildNode?.recycle()
  }

  aboutToReuse(data: ESObject) {
    console.log(this.TAG, "aboutToReuse type = " + this.type + " id = " + this.id)
    this.data = data
    this.mBuildNode?.update(data) //只能更新objectlink link prop的变量
    this.mBuildNode?.reuse(data) // 调用节点aboutToReuse
  }

  reuse() {
    this.mBuildNode?.reuse(this.data)
  }

  dispose() {
    this.unRegisterEnvCallback()
    this.mBuildNode?.dispose()
  }

  makeNode(uiContext: UIContext, isMeasure: boolean = false): FrameNode | null {
    if (!this.mBuildNode) {
      this.mBuildNode  = new BuilderNode(uiContext)
      this.mBuildNode.build(this.wrapperBuilder, this.data)
      let uniqueId = this.mBuildNode.getFrameNode()?.getUniqueId()
      this.registerEnvCallback()
      console.log(this.TAG, "makeNode type =" + this.type + " nodeId=" + this.id + " uniqueId=" + uniqueId)
    } else {
      this.isFirstRender = false
      this.mBuildNode?.update(this.data)
      console.log(this.TAG, "reuse node type =" + this.type + " nodeId=" + this.id + " parent=" + (this.mBuildNode.getFrameNode()?.getParent() === null))
    }
    let frameNode = this.mBuildNode.getFrameNode()
    if (frameNode && isMeasure) {
      frameNode.measure({ maxSize: { width: 0, height: 0}, minSize: { width: 0, height: 0}, percentReference: { width: 0, height: 0} })
    }
    return frameNode
  }

  aboutToAppear(): void {
    console.log(this.TAG, "aboutToAppear id = " + this.id + " type: " + this.type)
  }

  aboutToDisappear(): void {
    console.log(this.TAG, "aboutToDisappear id = " + this.id + " type: " + this.type)
  }

  update(data: ESObject) {
    this.data = data
    this.mBuildNode?.update(this.data)
  }

  onConfigurationUpdated() {
    this.mBuildNode?.updateConfiguration()
  }
}