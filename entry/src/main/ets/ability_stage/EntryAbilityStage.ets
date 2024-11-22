import { AbilityStage } from "@kit.AbilityKit";
import { ViewPoolInitTask } from "../global_viewpool/ViewPoolInitTask";

export default class EntryAbilityStage extends AbilityStage {
  onCreate(): void {
    let task = new ViewPoolInitTask(this.context)
    task.run()
  }
}