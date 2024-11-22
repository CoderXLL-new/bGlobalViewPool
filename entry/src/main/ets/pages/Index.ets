import { ViewPoolContainer, ViewPoolManager } from 'byte_global_viewpool';
import { ViewPoolTypeConstants } from '../global_viewpool/ViewPoolTypeConstants';
import { ContentSlice, gContentSliceWrapper, getContentSliceParams } from '../ReusedView/ContentSlice';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World Index';

  aboutToAppear(): void {
    /*
     * 1. 预创建的时机不一定在这里，可以更早一些。在这里预创建其实已经晚了
     * 2. timeout建议为4ms
     * 3. 这里提前预创建了4个ContentSlice，也就是说复用池里有4个ContentSlice FrameNode
     * */
    ViewPoolManager.getInstance().preCreateBuilderOnIdleFrame(this.getUIContext(), gContentSliceWrapper, getContentSliceParams(),
      ViewPoolTypeConstants.CONTENT_SLICE, 4000000, 4)
  }

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
      Button("跳转")
        .onClick(()=>{
          router.pushUrl({
            url: 'pages/Index1'
          }, router.RouterMode.Standard, (err) => {
            if (err) {
              console.error(`Invoke pushUrl failed, code is ${err.code}, message is ${err.message}`);
              return;
            }
            console.info('Invoke pushUrl succeeded.');
          });
        })
    }
    .height('100%')
    .width('100%')
  }
}