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

import { ArrayList } from "@kit.ArkTS"
import { MissionFrameOnIdleEngine } from "../mission/MissionFrameOnIdleEngine"
import { SplitTasksRunner } from "./SplitTasksRunner"

export class ScheduleService {
  private static mSplitTasksRunner: SplitTasksRunner = new SplitTasksRunner()

  /**
   * @description 任务组打散执行，目前打散时间为8ms
   * @param {ArrayList<()=>void>} taskList 任务组
   * @param {string} name 任务组名称
   * */
  public static postSplitTasks(taskList: ArrayList<()=>void>, name: string) {
    let count = taskList.length
    if (count === 0) return
    for (let i = 0; i < count; i++) {
      ScheduleService.mSplitTasksRunner.addTask(taskList[i], name)
    }
  }

  /**
   * @description 下一帧的OnIdle时机调用，主要用于预创建组件
   * @param {UIContext} uiContext
   * @param {()=>void>} callback
   * @param {number} timeout 如果OnIdle剩余时间小于timeout，不执行callback
   * */
  public static postFrameOnIdleCallback(uiContext: UIContext, callback: () => void, timeout: number) {
    try {
      MissionFrameOnIdleEngine.getInstance().addOnIdleTask(uiContext, callback, timeout)
    } catch (error) {
    }
  }

  /**
   * @description 下一帧的OnIdle时机调用，主要用于预创建组件
   * @param {UIContext} uiContext
   * @param {ArrayList<()=>void>} taskList
   * @param {number} timeout 如果OnIdle剩余时间小于timeout，不执行callback
   * */
  public static postFrameOnIdleTaskList(uiContext: UIContext, taskList: ArrayList<()=>void>, timeout: number) {
    try {
      MissionFrameOnIdleEngine.getInstance().addOnIdleTaskList(uiContext, taskList, timeout)
    } catch (error) {
    }
  }

  /**
   * @description 强制执行任务
   * @param {()=>void} callback
   * @param {number} delayTime 延迟时间(ms)
   * */
  public static executeTaskForce(callback: ()=>void, delayTime: number) {
    setTimeout(callback, delayTime) // 使用setTimeout插入正常任务队列执行
  }
}