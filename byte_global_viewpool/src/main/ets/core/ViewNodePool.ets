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

import { LightWeightMap } from '@kit.ArkTS'
import { ViewNodeCtrlImpl } from './ViewNodeCtrlImpl'
import { BuilderNode } from '@kit.ArkUI'
import { ViewPoolConfig } from '../ViewPoolConfig'
import { ViewPoolManager } from '../ViewPoolManager'

export class ViewNodePool {
  TAG: string = "ViewNodePool"
  private static instance: ViewNodePool
  private nodePool: LightWeightMap<string, Array<ViewNodeCtrlImpl>>
  private typeCountMap: LightWeightMap<string, number>
  private typeNodeMaxCountMap: LightWeightMap<string, number> = new LightWeightMap<string, number>()
  private nodeMaxCount: number = 20
  private enablePreCreateWhenEmpty: boolean = false
  private preCreateDataFuncMap: LightWeightMap<string, Function> = new LightWeightMap<string, Function>()
  private preCreateCountWhenEmpty: number = 2

  private constructor() {
    this.nodePool = new LightWeightMap<string, Array<ViewNodeCtrlImpl>>()
    this.typeCountMap = new LightWeightMap<string, number>()
  }

  public static getInstance() {
    if (!ViewNodePool.instance) {
      ViewNodePool.instance = new ViewNodePool()
    }
    return ViewNodePool.instance
  }

  public initConfig(config: ViewPoolConfig) {
    this.typeNodeMaxCountMap = config.typeNodeMaxCountMap
    this.nodeMaxCount = config.nodeMaxCount
    this.enablePreCreateWhenEmpty = config.enablePreCreateWhenEmpty
    this.preCreateDataFuncMap = config.preCreateDataFuncMap
    this.preCreateCountWhenEmpty = config.preCreateCountWhenEmpty // 暂时没用
  }

  public clearPool() {
    this.nodePool.clear()
  }

  public getNextIdByType(type: string): number {
    if (!this.typeCountMap.hasKey(type)) {
      this.typeCountMap.set(type, 1)
      return 1
    }
    let count = this.typeCountMap.get(type)
    count = count + 1
    this.typeCountMap.set(type, count)
    return count
  }

  private makeNewNode(type: string, data: ESObject, builder:WrappedBuilder<ESObject>):ViewNodeCtrlImpl {
    let node = new ViewNodeCtrlImpl(builder, data, type)
    return node
  }

  public getNode(type: string, data: ESObject, builder:WrappedBuilder<ESObject>): ViewNodeCtrlImpl {
    console.log(this.TAG, "getNode type=" + type + " hasKey: " + this.nodePool.hasKey(type));
    if (!this.nodePool.hasKey(type)) {
      return this.makeNewNode(type, data, builder)
    }
    let nodeArray = this.nodePool.get(type)
    let node: ViewNodeCtrlImpl
    if (nodeArray.length != 0) {
      node = nodeArray.pop()!
      node.data = data
      //node.aboutToReuse(data) // 不在这里走aboutToReuse
      console.log(this.TAG, "getReuseNode type=" + type + " nodeId=" + node.id + " uniqueId=" + node.getBuildNode()?.getFrameNode()?.getUniqueId() + " count=" + nodeArray.length)
    } else {
      console.log(this.TAG, "nodeArray empty and make new node, type=" + type)
      node = this.makeNewNode(type, data, builder)
    }
    if (nodeArray.length === 0 ) this.checkAndPreCreateForIdle(type, data, builder)
    return node
  }

  public checkAndPreCreateForIdle(type: string, data: ESObject, builder:WrappedBuilder<ESObject>) {
    if (!this.enablePreCreateWhenEmpty) return
    let dataFunc = this.preCreateDataFuncMap.get(type) // TODO 这里需要深拷贝数据，暂时用预置数据处理
    if (dataFunc === undefined) return
    console.log(this.TAG, "checkAndPreCreateForIdle type=" + type)
    // 只有在OnIdle剩余时间大于4ms才去预创建
    ViewPoolManager.getInstance().preCreateBuilderOnIdleFrameNoContext(builder, dataFunc(), type, 4000000)
  }

  public getNodeCount(type: string): number {
    if (!this.nodePool.hasKey(type)) {
      return 0
    }
    return this.nodePool.get(type).length
  }

  public recycleNode(type: string, node: ViewNodeCtrlImpl) {
    let nodeArray: Array<ViewNodeCtrlImpl> = this.nodePool.get(type)
    if (!nodeArray) {
      nodeArray = new Array<ViewNodeCtrlImpl>()
      this.nodePool.set(type, nodeArray)
    }
    let typeNodeMaxCount = this.typeNodeMaxCountMap.hasKey(type) ? this.typeNodeMaxCountMap.get(type) : 0
    let realMaxCount = typeNodeMaxCount != 0 ?  typeNodeMaxCount : this.nodeMaxCount
    if (nodeArray.length >= realMaxCount) {
      console.log(this.TAG, "recycleNode fail max type=" + type + "nodeId=" + node.id  + " length=" + nodeArray.length)
      node.dispose()
      return
    }
    let buildNode: BuilderNode<ESObject> | null = node.getBuildNode()
    if (buildNode !== null) {
      nodeArray.push(node)
      let frameNode = buildNode.getFrameNode()
      let uniqueId = frameNode?.getUniqueId()
      console.log(this.TAG, "recycleNode type=" + type + " nodeId="+ node.id  + " uniqueId=" + uniqueId + " count=" + this.getNodeCount(type))
    }
  }

  public preCreateNode(uiContext: UIContext, builder: WrappedBuilder<ESObject>, data: ESObject, type: string, isMeasure: boolean = false) {
    console.log(this.TAG, "preCreateNode type=" + type)
    // 1. 先创建ViewNodeCtrlImpl
    let viewNodeCtrlImpl = new ViewNodeCtrlImpl(builder, data, type)
    // 2. NodeController的BuilderNode创建
    viewNodeCtrlImpl.makeNode(uiContext, isMeasure)
    // 3. 主动触发aboutToRecycle
    viewNodeCtrlImpl.recycle()
    // 4. 回收ViewNodeCtrlImpl
    this.recycleNode(type, viewNodeCtrlImpl)
  }
}