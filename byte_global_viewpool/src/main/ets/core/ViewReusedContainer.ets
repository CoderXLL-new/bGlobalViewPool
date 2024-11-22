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

import { ViewNodeCtrlImpl } from './ViewNodeCtrlImpl'
import { ViewNodePool } from './ViewNodePool'

@Component
export struct ViewReusedContainer{
  TAG: string = "ViewReusedContainer"
  private nodeController: ViewNodeCtrlImpl | undefined
  type: string = ""
  params: ESObject
  builder: WrappedBuilder<ESObject>| undefined

  aboutToAppear(): void {
    this.nodeController = ViewNodePool.getInstance().getNode(this.type, this.params, this.builder!)
    console.log(this.TAG, "aboutToAppear type: " + this.type)
  }

  aboutToReuse(params: ESObject): void {
    console.log(this.TAG, "aboutToReuse type: " + this.type)
    this.nodeController?.aboutToReuse(params.params) //这里更新数据
    this.params = params.params
  }

  aboutToDisappear(): void {
    console.log(this.TAG, "aboutToDisappear type: " + this.type)
    if (this.nodeController) {
      this.nodeController?.recycle()
      ViewNodePool.getInstance().recycleNode(this.type, this.nodeController!)
      this.nodeController = undefined
    }
  }

  aboutToRecycle(): void {
    console.log(this.TAG, "aboutToRecycle type: " + this.type)
    this.nodeController?.recycle()
  }

  onDidBuild(): void {
    if (!this.nodeController?.isFirstRender) {
      // 这里走复用性能会更好
      console.log(this.TAG, "onDidBuild type: " + this.type)
      this.nodeController?.reuse()
    }
  }

  build() {
    NodeContainer(this.nodeController)
  }
}