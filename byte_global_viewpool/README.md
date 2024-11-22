# @bytedance/byte_global_viewpool
@bytedance/byte_global_viewpool是字节跳动自研鸿蒙组件全局复用池解决方案。https://github.com/bytedance/bGlobalViewPool

## 简介
本项目主要基于OpenHarmony NodeController与BuilderNode自定义挂载能力实现，从24年4月开始与华为深度合作完成。核心功能如下：

- 业务轻量化接入自定义组件全局复用能力，业务生命周期与系统无差异。
- 自定义组件全局预创建能力，保证组件首次使用直接复用
- 具备复用池自动补池子能力
- 支持全局开关配置
- 支持节点类型数量阈值配置
- 支持OnIdle预创建能力
- 支持跨端组件预创建能力
- 提供eventbus用于解决复用池组件与父组件状态变量链条断开问题
- 提供全局清除复用池接口
- 适配节点系统配置更新能力，比如暗黑模式

解决核心问题

- 解决跨端组件预创建能力
- 采用update与reuse拆帧处理降低丢帧
- 与华为合作OnIdle接口预创建组件，防止阻塞主线程
- 复用池自动补充池子能力，解决长列表池子快速清空的问题，大幅提升流畅度
- 解决系统OnIdle任务积压导致掉帧问题


待实现特性

- 监听内存，自定义清除或降低缓存
- 自动补池子采用深拷贝技术，不再需要配置预置数据Func
- 适配V2装饰器

## 下载安装

```
ohpm install @bytedance/byte_global_viewpool
```

## 使用说明

注：详细代码可见Entry
#### 1.初始化

```
// 启动阶段
let config = new ViewPoolConfig()
this.initConifg(config)
ViewPoolManager.getInstance().initViewPoolConfig(config) // 设置配置
ViewPoolManager.getInstance().initContext(this.context) // 设置Context
ViewPoolManager.getInstance().setEnable(true) // 全局控制组件全局复用池的开关，true为打开。

function initConfig(config: ViewPoolConfig) {
    config.enablePreCreateWhenEmpty = true // 当复用池最后一个节点使用完时，是否使用闲时预创建该类型节点
    /*
        export function getAuthorInfoSliceParams(): ESObject
        {
              return {vm : new AuthorInfoSliceViewModel()}
        }        
    */
    // preCreateDataFuncMap要配合enablePreCreateWhenEmpty使用，只有设置了数据生成function的类型才能走闲时创建
    config.preCreateDataFuncMap.set("type", getAuthorInfoSliceParams)
    config.preCreateCountWhenEmpty = 2 // 目前没有在使用
    config.nodeMaxCount = 20 // 每个节点最大缓存数量
}
```

#### 2.设置UIContext

注：不是必要设置
```
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      ViewPoolManager.getInstance().setUIContext(windowStage.getMainWindowSync().getUIContext())
    });
  }
```

#### 3.组件复用接入

```
// 第一步：业务组件提供全局创建Builder，并用WrapperBuilder封装
export const gContentSliceWrapper: WrappedBuilder<ESObject> = wrapBuilder<ESObject>(ContentSliceBuilder)

@Builder
export function ContentSliceBuilder($$: ESObject) {
  ContentSlice({
    mText: $$.mText
  })
}

// 第二步：使用Module接入xxx
  "dependencies": {
    "byte_global_viewpool": "file:../byte_global_viewpool"
  }
  
// 第三步：接入位置使用ViewPoolContainer容器封装即可
type：复用类型，一般为组件名
params：即传参
builder：组件全局WrapperBuilder
ViewPoolContainer({
    type: ViewPoolTypeConstants.CONTENT_SLICE,
    params: {
        mText: "我是复用池Text"
    },
    builder: gContentSliceWrapper
})
```

#### 4.OnIdle预创建

前置条件：预创建的组件需要由复用池容器承载
```
第一步：业务组件提供全局创建Builder，同时提供获取预创建数据的function，这里一般都是空model
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

第二步：使用ViewPoolManager preCreateBuilderOnIdleFrame通过vsync周期内的OnIdle时机预创建
/*
* @description 通过UIContext的OnIdle时机预创建组件节点，下次使用快速复用。
* @param uiContext 组件的上下文，与WindowStage绑定，即窗口。
* @param builder 组件全局创建Builder入口
* @param data 这个需要重点关注，需要构建一个空的ViewModel对象，否则会崩溃
* @param type 复用的类型
* @param timeout(ns) onIdle剩余时间阈值，大于这个阈值才会预创建
* @param count 预创建的数量，默认为1
* @param isMeasure 是否主动调用framnode.measure，默认为false。主要为lynx卡片预创建使用
* */
  preCreateBuilderOnIdleFrame(uiContext: UIContext, builder: WrappedBuilder<ESObject>, data: ESObject, type: string, timeout: number, count: number = 1, isMeasure: boolean = false) {
      ...
  }
  
  // 注意这里走的vsync OnIlde的时机预创建，当vysnc剩余时间大于timeout(这里设置的是4ms)才会预创建
  // 因此预创建的组件要保证4ms能渲染出来，否则可能会掉帧
 ViewPoolManager.getInstance().preCreateBuilderOnIdleFrame(uiContext, gAuthorInfoSliceWrapper, getAuthorInfoSliceParams(),
      ViewPoolTypeConstants.UGC_POSTCARD_AUTHOR_INFO_SLICE, 4000000, 4)
```
## 生命周期日志解析

Demo为Entry
```
启动APP，进入Index页面
ContentSliceTAG aboutToAppear 我不是复用池Text // 非复用池组件走正常生命周期
ContentSliceTAG aboutToAppear 我是复用池Text // 复用池组件，由于没有预创建的组件进入池子，因此走正常的生命周期
// 预创建4个ContentSlice组件，生命周期先创建再回收，符合预期
ContentSliceTAG aboutToAppear 预创建组件
ContentSliceTAG aboutToRecycle 预创建组件
ContentSliceTAG aboutToAppear 预创建组件
ContentSliceTAG aboutToRecycle 预创建组件
ContentSliceTAG aboutToAppear 预创建组件
ContentSliceTAG aboutToRecycle 预创建组件
ContentSliceTAG aboutToAppear 预创建组件
ContentSliceTAG aboutToRecycle 预创建组件

跳转进入Index1页面
ContentSliceTAG aboutToAppear 我不是复用池Text // 非复用池组件走正常生命周期
ContentSliceTAG aboutToReuse 我是复用池Text // 复用池组件，复用池有缓存直接走aboutToReuse，不需要走重新创建

返回Index页面
ContentSliceTAG aboutToRecycle 我是复用池Text // 复用池组件回收到复用池
```

## 相关数据

1. 复用池使用收益(提升40%)
   - 频道滑动(使用前)：Jank率(1.1%/0.9%/1.3%)、最长帧耗时(20ms/19ms/18ms)
   - 频道滑动(使用后)：Jank率(0.6%/0.7%/0.7%)、最长帧耗时(13ms/15ms/14ms)
   - 分析：由于长列表滑动开始前没有预创建，开始滑动Jank率较高。且滑动过快或过长池子很容易为空，复用池偶先效果不明显
2. 预创建+补池子(提升50%)
   - 频道滑动：Jank率(0.3%/0.5%/0.2%)、最长帧耗时(9ms/8ms/9ms)
   - 分析：预创建解决列表首次滑动需要创建组件的丢帧，补池子解决长时间滑动池子很快为空的问题

## 注意事项

1. 不能传递Provide类型，因为这个是自定义组件链的，NodeContainer已经打破了这个链，所以需要在手动传入
2. 数据是一次性的，不支持同步响应，因为状态变量链条已经断裂
3. 基础组件会低概率丢掉父容器的宽高，需要自定组件自己设置一下。目前只发现Text会有这个问题，一般自定义组件都会有容器包裹不会有这个问题。
4. 复用组件不能被@Reusable修饰，否则会崩溃
5. 自定义测量的跨端组件，即带有onMeasureSize的组件预创建无法触发aboutToAppear。系统原因：带有onMeasureSize的组件被识别为系统组件，预创建组件无法触发aboutToAppear
6. 自定义Image组件需要在aboutToRecycle清空数据。

## 技术支持
1. 邮件: <a href="mailto:wuqizhao@bytedance.com">wuqizhao@bytedance.com</a>
## License
~~~
Copyright (2024) Bytedance Ltd. and/or its affiliates

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
~~~
