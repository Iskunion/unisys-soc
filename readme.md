# Unisys soc

## 核心侧

核心侧的部件定义见 `core/`文件夹。

### MMU

Unisys 核心使用的 MMU 向 CPU 模拟一块 32 位宽的 IO 地址空间，由于总线实际上已经完成了从设备的内存映射，因此只需要简单的进行地址线分流和数据转发即可。

## 边缘侧

边缘侧的部件定义见 `perf/`文件夹。

### 总线
Unisys 使用简单设计的 UIB（Unisys Internal Bus） 总线。

UIB 从核心可用的 IO 地址中提取高位（默认提取 4 位）作为从设备编码，余下的位宽则为从设备地址编码，从而为每个主设备模拟出一个统一的、和字长相符合的 IO 地址空间。

而对于主设备同时发起的读写事务，UIB采用固定优先级仲裁机制，主设备编号小者优先级高，在 Unisys 中，核心的 MMU 是第 0 号主设备，从而有着最高的优先级，其余 DMA 设备则在其次。

总线的实现位于`perf/uib.sv`。

### 总线接口

UIB 为主、从设备各定义了一种接口标准，并将所有的设备接口都统一在该标准下。

具体地，UIB 要求主、从设备拥有数据、地址、模式、协商四套 IO 线路，另外，主设备还需要额外指明要访问的从设备总线号。藉由这种标准，`perf/uibi.sv` 中利用宏和模块封装了一些通用于 UIBI 设备的接口和功能。

### 主存储器

Unisys 使用由四片大小为 64 KB 的，存储单元为一个字节的 RAM 组成主存。此主存一次吞吐出一个字的数据，截取的内容由总线指定的读写模式来决定，读写地址则使用总线地址的低 18 位。
另外，Unisys 不区分数据、指令存储器，也不采用多级缓存结构，而且不进行存储保护，所有地址均可读写。

主存储器的实现位于 `perf/mainmem.sv`。

### 时钟

Unisys 的时钟支持设置硬件时钟中断，设置系统时间，查询系统运行至今时间戳三种功能。<br />时钟提供三个设备寄存器，可以通过总线地址访问：

- 系统时间寄存器，地址 `0x00`，可读可写，储存标准 UNIX 时间戳。
- 运行时间戳寄存器，地址 `0x04`，只读，储存系统运行至今的微秒数。
- 中断间隔时长寄存器，地址 `0x08`，可读可写，储存以微秒计算的时钟中断间隔时长。

时钟的实现位于 `perf/timer.sv`。

### 串口

### 键盘