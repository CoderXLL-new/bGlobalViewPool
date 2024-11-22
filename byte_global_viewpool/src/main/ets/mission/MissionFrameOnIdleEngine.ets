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

import { ArrayList, Stack } from "@kit.ArkTS"
import { FrameCallback } from "@kit.ArkUI"

export class MissionFrameOnIdleEngine {
  private static instance: MissionFrameOnIdleEngine
  private taskStack: Stack<MissionFrameOnIdleSingleTask> = new Stack<MissionFrameOnIdleSingleTask>()
  private isRunning: boolean = false

  private constructor() {
  }

  public static getInstance(): MissionFrameOnIdleEngine {
    if (!MissionFrameOnIdleEngine.instance) {
      MissionFrameOnIdleEngine.instance = new MissionFrameOnIdleEngine()
    }
    return MissionFrameOnIdleEngine.instance
  }

  getNextOnIdleTask(): MissionFrameOnIdleSingleTask | undefined {
    if (this.taskStack.isEmpty()) {
      return undefined
    }
    return this.taskStack.pop()
  }

  addOnIdleTask(uiContext: UIContext, task: ()=>void, timeout: number) {
    let onIdleFrameTask = new MissionFrameOnIdleSingleTask(uiContext, task, timeout)
    this.taskStack.push(onIdleFrameTask)
    this.tryRun(uiContext)
  }

  addOnIdleTaskList(uiContext: UIContext, taskList: ArrayList<()=>void>, timeout: number) {
    for (const task of taskList) {
      let onIdleFrameTask = new MissionFrameOnIdleSingleTask(uiContext, task, timeout)
      this.taskStack.push(onIdleFrameTask)
    }
    this.tryRun(uiContext)
  }

  tryRun(uiContext: UIContext) {
    if (!this.isRunning) {
      let task = this.getNextOnIdleTask()
      if (task) {
        this.isRunning = true
        uiContext.postFrameCallback(task)
      }
    }
  }

  setRunningState(state: boolean) {
    this.isRunning = state
  }

  getRunningState(): boolean {
    return this.isRunning
  }

}

class MissionFrameOnIdleSingleTask extends FrameCallback {
  private uiContext: UIContext
  private onIdleCallback: ()=>void
  private timeout: number

  constructor(uiContext:UIContext, onIdleCallback: ()=>void, timeout: number) {
    super()
    this.uiContext = uiContext
    this.onIdleCallback = onIdleCallback
    this.timeout = timeout
  }

  onIdle(timeLeftInNano: number) : void {
    if (timeLeftInNano >= this.timeout) {
      this.onIdleCallback()
      let nextTask = MissionFrameOnIdleEngine.getInstance().getNextOnIdleTask()
      if (nextTask !== undefined) {
        this.uiContext.postFrameCallback(nextTask)
      } else {
        MissionFrameOnIdleEngine.getInstance().setRunningState(false)
      }

    } else {
      this.uiContext.postFrameCallback(this)
    }
  }
}