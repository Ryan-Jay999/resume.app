import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { fileIo as fs, picker } from '@kit.CoreFileKit';
import { Resume } from '../model/Models';
import { LocalStore } from '../service/LocalStore';

@Entry
@Component
struct Settings {
  private async exportBackup(): Promise<void> {
    try {
      const documentPicker: picker.DocumentViewPicker =
        new picker.DocumentViewPicker(getContext(this) as common.UIAbilityContext);
      const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
      options.newFileNames = ['jiantu_backup.json'];
      const uris: string[] = await documentPicker.save(options);
      if (uris.length === 0) {
        return;
      }
      const text: string = LocalStore.toBackupText();
      const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, text);
      } finally {
        fs.closeSync(file);
      }
      promptAction.showToast({ message: '备份已导出' });
    } catch (err) {
      console.error('export backup failed: ' + JSON.stringify(err));
      promptAction.showToast({ message: '导出失败，请重试' });
    }
  }

  private confirmImport(): void {
    AlertDialog.show({
      title: '导入备份',
      message: '导入会覆盖当前所有简历与计划数据，确定继续吗？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '继续',
        fontColor: '#2563EB',
        action: () => {
          this.importBackup();
        }
      }
    });
  }

  private async importBackup(): Promise<void> {
    try {
      const documentPicker: picker.DocumentViewPicker =
        new picker.DocumentViewPicker(getContext(this) as common.UIAbilityContext);
      const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['.json'];
      const uris: string[] = await documentPicker.select(options);
      if (uris.length === 0) {
        return;
      }
      const cachePath: string = getContext(this).cacheDir + '/jiantu_import.json';
      fs.copyFileSync(uris[0], cachePath);
      const text: string = fs.readTextSync(cachePath);
      const ok: boolean = LocalStore.restoreFromText(text);
      if (ok) {
        const resumes: Resume[] = LocalStore.loadResumes();
        promptAction.showToast({ message: '已导入 ' + resumes.length.toString() + ' 份简历' });
      } else {
        promptAction.showToast({ message: '文件格式不正确' });
      }
    } catch (err) {
      console.error('import backup failed: ' + JSON.stringify(err));
      promptAction.showToast({ message: '导入失败，请检查文件' });
    }
  }

  private confirmClear(): void {
    AlertDialog.show({
      title: '清空数据',
      message: '将删除本机全部简历与计划，且无法恢复。建议先导出备份。',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '清空',
        fontColor: '#EF4444',
        action: () => {
          LocalStore.clearAll();
          promptAction.showToast({ message: '已清空' });
        }
      }
    });
  }

  @Builder
  settingRow(title: string, desc: string, action: () => void) {
    Row() {
      Column({ space: 3 }) {
        Text(title)
          .fontSize(14)
          .fontColor('#111827')
        Text(desc)
          .fontSize(11)
          .fontColor('#9CA3AF')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('›')
        .fontSize(20)
        .fontColor('#C4C8CE')
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .onClick(action)
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
        Text('设置')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 10 })

      Scroll() {
        Column({ space: 12 }) {
          Column() {
            this.settingRow('导出备份', '生成 JSON 备份文件，换设备时使用', () => {
              this.exportBackup();
            })
            Divider().color('#F3F4F6')
            this.settingRow('导入备份', '从 JSON 备份恢复简历与计划', () => {
              this.confirmImport();
            })
            Divider().color('#F3F4F6')
            this.settingRow('清空全部数据', '删除本机所有简历与成长计划', () => {
              this.confirmClear();
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
          .borderRadius(14)

          Column({ space: 10 }) {
            Text('隐私说明')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#111827')
              .width('100%')
            Text('简途是一款完全离线的本地应用：')
              .fontSize(12)
              .fontColor('#4B5563')
              .width('100%')
            Text('· 不申请网络权限，不具备联网能力')
              .fontSize(12)
              .fontColor('#4B5563')
              .width('100%')
            Text('· 不收集账号、手机号或任何个人信息')
              .fontSize(12)
              .fontColor('#4B5563')
              .width('100%')
            Text('· 简历与计划仅保存在本机应用沙箱内')
              .fontSize(12)
              .fontColor('#4B5563')
              .width('100%')
            Text('· 卸载应用即删除全部数据')
              .fontSize(12)
              .fontColor('#4B5563')
              .width('100%')
            Text('· 导出 PDF 与备份由你手动选择保存位置')
              .fontSize(12)
              .fontColor('#4B5563')
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .alignItems(HorizontalAlign.Start)

          Column({ space: 6 }) {
            Text('简途 1.0.0')
              .fontSize(13)
              .fontColor('#374151')
            Text('离线简历工具 · 自检诊断 · 成长规划')
              .fontSize(11)
              .fontColor('#9CA3AF')
          }
          .width('100%')
          .padding({ top: 24, bottom: 24 })

          Text('提示：上架前请补全应用备案与隐私政策链接。')
            .fontSize(10)
            .fontColor('#C4C8CE')
            .margin({ bottom: 24 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F5F7')
  }
}
