# 项目简述
本实验是基于`FPGA`以及`SD`卡的印刷体数字识别实验

# 项目说明
将一些含有单个数字的图片文件转化为`Bin`文件存入`SD`卡，通过`FPGA`将其依次显示在`VGA`上，并对图片中含有数字的区域进行框取并对数字进行识别显示在数码管上。

# 环境
## 硬件与外围模块
- 开发板：[Nexys4 DDR™ FPGA Board Reference Manual](https://reference.digilentinc.com/reference/programmable-logic/nexys-4-ddr/start)
- VGA：[TFT LCD COLOR MONITOR](http://www.tinyvga.com/vga-timing)
- SD卡：[MICRO SD CRAD (SD2.0)](https://www.sdcard.org/)

## 开发环境
- 开发工具：[VIVADO 2016.2](https://china.xilinx.com/products/design-tools/vivado.html)

## 软件工具
- 图片转换工具：Img2Lcd
- 磁盘读取工具：[WinHex64](http://www.x-ways.net/winhex/)

# 项目下板结果
- 见`report.pdf`