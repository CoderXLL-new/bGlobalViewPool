import { ViewPoolConfig } from "byte_global_viewpool"
import { getContentSliceParams } from "../ReusedView/ContentSlice"
import { ViewPoolTypeConstants } from "./ViewPoolTypeConstants"

export class ViewPoolConfigEx extends ViewPoolConfig {
  constructor() {
    super()
    this.enablePreCreateWhenEmpty = true // 当复用池最后一个节点使用完时，是否使用闲时预创建该类型节点
    this.preCreateCountWhenEmpty = 2 // 目前没有在使用
    this.nodeMaxCount = 20 // 最大缓存节点数量
    this.initPreCreateDataMap()
  }

  initPreCreateDataMap() {
    this.preCreateDataFuncMap.set(ViewPoolTypeConstants.CONTENT_SLICE, getContentSliceParams)
  }
}