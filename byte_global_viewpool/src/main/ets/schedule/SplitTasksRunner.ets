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

import { ScheduleService } from './ScheduleService'

class SplitSingleTask {
  name: string = "SplitSingleTask"
  taskRun: ()=> void
  next?: SplitSingleTask = undefined
  constructor(taskRun: ()=> void, name: string) {
    this.taskRun = taskRun
    if (name.trim().length > 0) {
      this.name = name
    }
  }

  public setNext(next: SplitSingleTask) {
    this.next = next
  }
}

export class SplitTasksRunner {
  private _taskHead?: SplitSingleTask = undefined
  private _taskTail?: SplitSingleTask = undefined

  constructor() {
  }

  public addTask(addTask: ()=> void, name: string) {
    if (this._taskHead === undefined) {
      this._taskHead = new SplitSingleTask(addTask, name)
      this._taskTail = this._taskHead
      this.pollTaskRun()
    } else {
      let task = new SplitSingleTask(addTask, name)
      this._taskTail?.setNext(task)
      this._taskTail = task
    }
  }

  private pollTaskRun() {
    if (this._taskHead !== undefined) {
      let task = ()=>{
        this._taskHead?.taskRun()
        this._taskHead = this._taskHead?.next
        this.pollTaskRun()
      }
      ScheduleService.executeTaskForce(task, 8)
    }
  }
}