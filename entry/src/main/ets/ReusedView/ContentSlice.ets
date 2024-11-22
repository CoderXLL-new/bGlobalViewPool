
@Component
export struct ContentSlice {
  @Prop mText: string = ""

  aboutToAppear(): void {
    console.log("ContentSliceTAG" , "aboutToAppear " + this.mText);
  }

  aboutToReuse(params: ESObject): void {
    console.log("ContentSliceTAG" , "aboutToReuse " + this.mText);
  }

  aboutToRecycle(): void {
    console.log("ContentSliceTAG" , "aboutToRecycle " + this.mText);
  }

  build() {
    Text(this.mText)
      .margin({ bottom: 8 })
      .fontSize(30)
      .fontWeight(FontWeight.Bold)
  }
}

export const gContentSliceWrapper: WrappedBuilder<ESObject> = wrapBuilder<ESObject>(ContentSliceBuilder)

// 这个函数用于获取预创建数据，要保证数据每次获取引用不一致
export function getContentSliceParams(): ESObject
{
  return {mText : "预创建组件"}
}

@Builder
export function ContentSliceBuilder($$: ESObject) {
  ContentSlice({
    mText: $$.mText
  })
}