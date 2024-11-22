import { ViewPoolManager } from "byte_global_viewpool"
import { ViewPoolConfigEx } from "./ViewPoolConfigEx"

export class ViewPoolInitTask {
  tag = "QualityLaunchTask"
  context: Context
  constructor(context: Context) {
    // 需要用context，而不是applicationContext
    this.context = context
  }

  run(): void {
    let config = new ViewPoolConfigEx()
    ViewPoolManager.getInstance().initViewPoolConfig(config)
    ViewPoolManager.getInstance().initContext(this.context)
    ViewPoolManager.getInstance().setEnable(true) //全局控制组件全局复用池开关，true为打开
  }
}