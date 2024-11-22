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

export class ViewPoolConfig {
  /*
   * 设置指定类型Node的最大缓存数量
   * */
  typeNodeMaxCountMap: LightWeightMap<string, number> = new LightWeightMap<string, number>()

  /*
   * 设置Node默认的最大缓存数量
   * */
  nodeMaxCount: number = 20

  /*
   * 当复用池最后一个节点使用完时，是否使用闲时预创建该类型节点
   * */
  enablePreCreateWhenEmpty: boolean = false

  /*
   * 配置闲时预创建数据生成函数
   * */
  preCreateDataFuncMap: LightWeightMap<string, Function> = new LightWeightMap<string, Function>()

  /*
   * 当复用池最后一个节点使用完时，预创建该类型节点数量
   * */
  preCreateCountWhenEmpty: number = 2

  public setTypeNodeCount(type:string, count: number) {
    this.typeNodeMaxCountMap.set(type, count)
  }
}