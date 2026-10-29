@Component
export struct FieldRow {
  label: string = '';
  initial: string = '';
  placeholder: string = '';
  multiline: boolean = false;
  onValue: (value: string) => void = (value: string) => {};

  @State inner: string = '';

  aboutToAppear(): void {
    this.inner = this.initial;
  }

  build() {
    Column({ space: 6 }) {
      Text(this.label)
        .fontSize(12)
        .fontColor('#6B7280')
        .width('100%')
      if (this.multiline) {
        TextArea({ text: this.inner, placeholder: this.placeholder })
          .height(100)
          .fontSize(14)
          .backgroundColor('#F7F8FA')
          .borderRadius(8)
          .onChange((value: string) => {
            this.inner = value;
            this.onValue(value);
          })
      } else {
        TextInput({ text: this.inner, placeholder: this.placeholder })
          .height(42)
          .fontSize(14)
          .backgroundColor('#F7F8FA')
          .borderRadius(8)
          .onChange((value: string) => {
            this.inner = value;
            this.onValue(value);
          })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }
}
