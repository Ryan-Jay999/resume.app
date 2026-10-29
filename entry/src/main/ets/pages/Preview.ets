import { common } from '@kit.AbilityKit';
import { componentSnapshot, promptAction, router } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { createEmptyResume, Resume, TemplateDef } from '../model/Models';
import { ResumePaper } from '../components/ResumePaper';
import { ConfigService } from '../service/ConfigService';
import { LocalStore } from '../service/LocalStore';
import { PdfService } from '../service/PdfService';

const FALLBACK_TEMPLATE: TemplateDef = {
  id: '',
  name: '',
  category: '',
  scene: 'internet_intern',
  accent: '#2563EB',
  layout: 'classic',
  desc: '',
  order: ['education', 'internship', 'project', 'award', 'studentWork', 'skills', 'certificates', 'summary']
};

@Entry
@Component
struct Preview {
  @State resume: Resume = createEmptyResume('', '');
  @State template: TemplateDef = FALLBACK_TEMPLATE;
  @State exporting: boolean = false;
  @State loaded: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    const found: Resume | undefined = LocalStore.findResume(params['id']);
    if (found === undefined) {
      promptAction.showToast({ message: '简历不存在' });
      return;
    }
    this.resume = found;
    const template: TemplateDef | undefined = ConfigService.getTemplate(found.templateId);
    if (template !== undefined) {
      this.template = template;
    }
    this.loaded = true;
  }

  private async exportPdf(): Promise<void> {
    if (this.exporting) {
      return;
    }
    this.exporting = true;
    try {
      const pixelMap: image.PixelMap = await componentSnapshot.get('resumePaper');
      const bytes: Uint8Array = await PdfService.build(pixelMap);
      pixelMap.release();

      const documentPicker: picker.DocumentViewPicker =
        new picker.DocumentViewPicker(getContext(this) as common.UIAbilityContext);
      const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
      let name: string = this.resume.title.length > 0 ? this.resume.title : '简历';
      name = name.replace('/', '_');
      options.newFileNames = [name + '.pdf'];
      const uris: string[] = await documentPicker.save(options);
      if (uris.length === 0) {
        return;
      }
      PdfService.write(uris[0], bytes);
      promptAction.showToast({ message: 'PDF 已导出' });
    } catch (err) {
      console.error('export pdf failed: ' + JSON.stringify(err));
      promptAction.showToast({ message: '导出失败，请重试' });
    } finally {
      this.exporting = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor('#111827')
          .width(32)
          .onClick(() => {
            router.back();
          })
        Text('简历预览')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
        Blank()
        if (this.exporting) {
          Row({ space: 6 }) {
            LoadingProgress()
              .width(16)
              .height(16)
              .color('#FFFFFF')
            Text('生成中')
              .fontSize(13)
              .fontColor('#FFFFFF')
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#9CA3AF')
          .borderRadius(14)
        } else {
          Text('导出 PDF')
            .fontSize(13)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.template.accent)
            .borderRadius(14)
            .onClick(() => {
              this.exportPdf();
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 10 })

      Scroll() {
        Column() {
          Column() {
            ResumePaper({ resume: this.resume, template: this.template })
          }
          .id('resumePaper')
          .width('100%')
          .backgroundColor('#FFFFFF')
          .borderRadius(4)
          .shadow({ radius: 12, color: '#1A000000', offsetY: 2 })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 6, bottom: 12 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      Row({ space: 10 }) {
        Text('返回编辑')
          .fontSize(14)
          .fontColor('#374151')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: 11, bottom: 11 })
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E5E7EB' })
          .borderRadius(10)
          .onClick(() => {
            router.back();
          })
        Text('一键诊断')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: 11, bottom: 11 })
          .backgroundColor(this.template.accent)
          .borderRadius(10)
          .onClick(() => {
            router.pushUrl({ url: 'pages/Diagnosis', params: { id: this.resume.id } });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      .backgroundColor('#F4F5F7')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F5F7')
  }
}
