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

import { LightWeightMap } from '@kit.ArkTS';

type Handler<T = ESObject> = (val: T) => void;

export class ViewPoolEventBus {
  private static instance: ViewPoolEventBus
  private observeId: number = 0
  private observeMap: LightWeightMap<string, Set<Handler>> = new LightWeightMap<string, Set<Handler>>()

  private constructor() {
  }

  private with(eventType: string): Set<Handler> {
    if (!this.observeMap.hasKey(eventType)) {
      let set = new Set<Handler>()
      this.observeMap.set(eventType, set)
    }
    return this.observeMap.get(eventType)!
  }

  public static getInstance() {
    if (!ViewPoolEventBus.instance) {
      ViewPoolEventBus.instance = new ViewPoolEventBus()
    }
    return ViewPoolEventBus.instance
  }

  public getObserveID():number {
    return this.observeId++;
  }

  observe(eventType: string, handler: Handler) {
    this.with(eventType).add(handler)
  }

  removeObserver(eventType: string, handler: Handler) {
    this.with(eventType).delete(handler)
  }

  removeAllObserver(eventType: string) {
    this.with(eventType).clear()
    this.observeMap.remove(eventType)
  }

  postEvent(eventType: string, value: ESObject) {
    let set = this.observeMap.get(eventType)
    if (!set) return
    set.forEach((fn) => fn(value))
  }
}