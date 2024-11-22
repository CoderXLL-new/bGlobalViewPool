import { ViewPoolContainer } from 'byte_global_viewpool';
import { ViewPoolTypeConstants } from '../global_viewpool/ViewPoolTypeConstants';
import { ContentSlice, gContentSliceWrapper } from '../ReusedView/ContentSlice';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World Index1';

  build() {
    Column() {
      Text(this.message)
        .id('HelloWorld')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
      ContentSlice({mText: "我不是复用池Text"})
      ViewPoolContainer({
        type: ViewPoolTypeConstants.CONTENT_SLICE,
        params: {
          mText: "我是复用池Text"
        },
        builder: gContentSliceWrapper
      })
    }
    .height('100%')
    .width('100%')
  }
}