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

import { ViewPoolManager } from './ViewPoolManager'
import { ViewReusedContainer } from './core/ViewReusedContainer'
import { ViewPoolParam } from './ViewPoolParam'

/*
 * 组件复用池容器，内部支持开关全局控制
 * */
@Component
export struct ViewPoolContainer{
  private isEnable: boolean = ViewPoolManager.getInstance().getEnable()
  type: string = ""
  params: ESObject
  builder: WrappedBuilder<ESObject>| undefined

  aboutToReuse(params: ESObject): void {
    if (this.isEnable) {
      this.params = params.params
    } else {
      Object.keys(params.params).forEach((key) => {
        this.params[key] = params.params[key]
      })
    }
  }

  build() {
    if (this.isEnable) {
      ViewReusedContainer({
        type: this.type,
        params: this.params,
        builder: this.builder
      })
    } else {
      this.builder?.builder(this.params)
    }
  }
}


/*
 * 提供一个Builder容器
 * 此容器不支持开关关闭，需要业务根据ViewPoolManager.getInstance().getEnable()做容错
 * */
@Builder
export function viewPoolContainerBuilder($$: ViewPoolParam) {
  ViewReusedContainer({
    type: $$.type,
    params: $$.params,
    builder: $$.builder
  })
}