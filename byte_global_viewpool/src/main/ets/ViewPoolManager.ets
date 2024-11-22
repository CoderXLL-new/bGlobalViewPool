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

import { ViewNodePool } from './core/ViewNodePool'
import { ScheduleService } from './schedule/ScheduleService'
import { ArrayList } from '@kit.ArkTS'
import { ViewPoolConfig } from './ViewPoolConfig'
import { Context } from '@kit.AbilityKit'

export class ViewPoolManager {
  private static instance: ViewPoolManager
  private isEnable: boolean = true
  private context?: Context
  private uiContext: UIContext | undefined
  private constructor() {
  }

  public static getInstance() {
    if (!ViewPoolManager.instance) {
      ViewPoolManager.instance = new ViewPoolManager()
    }
    return ViewPoolManager.instance
  }

  public setEnable(isEnable: boolean) {
    this.isEnable = isEnable
  }

  public getEnable(): boolean {
    return this.isEnable
  }

  public initContext(context: Context) {
    this.context = context
  }

  public getContext(): Context | undefined {
    return this.context
  }

  public setUIContext(uiContext: UIContext) {
    this.uiContext = uiContext
  }

  public initViewPoolConfig(config: ViewPoolConfig) {
    ViewNodePool.getInstance().initConfig(config)
  }

  public checkAndInitUIContext(context: UIContext) {
    if (this.uiContext === undefined) {
      this.uiContext = context
    }
  }

  public cleanPool() {
    ViewNodePool.getInstance().clearPool()
  }

  /*
   * @description 预创建组件节点，下次使用快速复用。
   * @param uiContext 组件的上下文，与WindowStage绑定，即窗口。
   * @param builder 组件全局创建Builder入口
   * @param data 这个需要重点关注，需要构建一个空的ViewModel对象，否则会崩溃
   * @param type 复用的类型
   * @param count 预创建的数量，默认为1
   * @param isMeasure 是否主动调用framenode.measure，默认为false。
   * */
  preCreateBuilder(uiContext: UIContext, builder: WrappedBuilder<ESObject>, data: ESObject, type: string, count: number = 1, isMeasure: boolean = false) {
    if (!this.isEnable) return
    if (count > 0) {
      for (let i = 0; i < count; i++) {
        // 主线程执行，可能会掉帧
        ViewNodePool.getInstance().preCreateNode(uiContext, builder, data, type, isMeasure)
      }
    }
  }

/*
 * @description 任务拆帧方式预创建组件节点，下次使用快速复用。
 * @param uiContext 组件的上下文，与WindowStage绑定，即窗口。
 * @param builder 组件全局创建Builder入口
 * @param data 这个需要重点关注，需要构建一个空的ViewModel对象，否则会崩溃
 * @param type 复用的类型
 * @param count 预创建的数量，默认为1
 * @param isMeasure 是否主动调用framenode.measure，默认为false。
 * */
  preCreateBuilderSplitTask(uiContext: UIContext, builder: WrappedBuilder<ESObject>, data: ESObject, type: string, count: number = 1, isMeasure: boolean = false) {
    if (!this.isEnable) return
    if (count > 0) {
      let list = new ArrayList<()=>void>()
      for (let i = 0; i < count; i++) {
        list.add(()=>{
          ViewNodePool.getInstance().preCreateNode(uiContext, builder, data, type, isMeasure)
        })
      }
      ScheduleService.postSplitTasks(list, "preCreateBuilder")
    }
  }

/*
* @description 通过UIContext的OnIdle时机预创建组件节点，下次使用快速复用。
* @param builder 组件全局创建Builder入口
* @param data 这个需要重点关注，需要构建一个空的ViewModel对象，否则会崩溃
* @param type 复用的类型
* @param timeout onIdle剩余时间阈值，大于这个阈值才会预创建
* @param isMeasure 是否主动调用framnode.measure，默认为false。主要为lynx卡片预创建使用
* @returns {boolean} 如果内部UIConext为空，返回false。正常执行返回true
* */
  preCreateBuilderOnIdleFrameNoContext(builder: WrappedBuilder<ESObject>, data: ESObject, type: string, timeout: number, isMeasure: boolean = false): boolean {
    if (!this.isEnable) return false
    if (this.uiContext) { // 需要通过setUIContext提前设置
      ScheduleService.postFrameOnIdleCallback(this.uiContext, ()=> {
        // 默认创建一个
        ViewNodePool.getInstance().preCreateNode(this.uiContext!, builder, data, type, isMeasure)
      }, timeout)
      return true
    }
    return false
  }

  /*
* @description 通过UIContext的OnIdle时机预创建组件节点，下次使用快速复用。
* @param uiContext 组件的上下文，与WindowStage绑定，即窗口。
* @param builder 组件全局创建Builder入口
* @param data 这个需要重点关注，需要构建一个空的ViewModel对象，否则会崩溃
* @param type 复用的类型
* @param timeout onIdle剩余时间阈值，大于这个阈值才会预创建
* @param count 预创建的数量，默认为1
* @param isMeasure 是否主动调用framnode.measure，默认为false。主要为lynx卡片预创建使用
* */
  preCreateBuilderOnIdleFrame(uiContext: UIContext, builder: WrappedBuilder<ESObject>, data: ESObject, type: string, timeout: number, count: number = 1, isMeasure: boolean = false) {
    if (!this.isEnable) return
    if (count > 0) {
      let taskList = new ArrayList<()=>void>()
      for (let i = 0; i < count; i++) {
        taskList.add(()=>{
          ViewNodePool.getInstance().preCreateNode(uiContext, builder, data, type, isMeasure)
        })
      }
      ScheduleService.postFrameOnIdleTaskList(uiContext, taskList, timeout)
    }
    this.checkAndInitUIContext(uiContext)
  }

  /**
   * 获取当前缓存池中的节点数量
   * @param type
   * @return number
   */
  public getPoolNodeCount(type: string): number {
    return ViewNodePool.getInstance().getNodeCount(type)
  }
}