# 基于`FPGA`以及`SD`卡的数字识别实验

## 说明

将若干张(满足SD容量)含有单个**印刷体**数字的图片文件转化为`bin`格式文件存入`SD`卡，通过`FPGA`将其依次显示在`VGA`上，并对图片中含有数字的区域进行框取并对数字进行识别显示在数码管上。

## 环境

### 硬件

- 开发板：[Nexys4 DDR™ FPGA Board](https://reference.digilentinc.com/reference/programmable-logic/nexys-4-ddr/start)

- VGA：[TFT LCD COLOR MONITOR](http://www.tinyvga.com/vga-timing)

- SD卡：[MICRO SD CRAD (SD2.0)](https://www.sdcard.org/)

### 工具

- 开发工具：[VIVADO 2016.2](https://china.xilinx.com/products/design-tools/vivado.html)

- 图片转换工具：[Img2Lcd](https://image2lcd.software.informer.com/3.2/)

- 磁盘读取工具：[WinHex64](http://www.x-ways.net/winhex/)

## 细节

- 见[Report](https://github.com/Yaozhtj/sdcard_digital_recognition/blob/master/report.pdf)

## 想法

- 为什么要强调SD卡？因为完成本项目80%的时间都用在SD卡的初始化、读写以及调试上了。

- 真的实现了所谓的数字识别吗？完全没有，说起来是数字识别，其实就是简单的特征识别，想要识别成功，还需要满足图片中仅有一个数字并且无其他像素干扰。与其说是数字识别，不如说是为了丰富项目功能增加的一些数据处理。
