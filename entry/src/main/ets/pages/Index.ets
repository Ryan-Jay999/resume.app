import { promptAction, router } from '@kit.ArkUI';
import {
  DiagItem,
  DiagReport,
  formatTime,
  PlanTask,
  Resume,
  TemplateDef
} from '../model/Models';
import { SampleData } from '../model/SampleData';
import { ConfigService } from '../service/ConfigService';
import { DiagnosisService } from '../service/DiagnosisService';
import { LocalStore } from '../service/LocalStore';

@Component
struct QuickAction {
  title: string = '';
  desc: string = '';
  color: string = '#2563EB';
  onTap: () => void = () => {};

  build() {
    Column({ space: 6 }) {
      Row()
        .width(22)
        .height(4)
        .backgroundColor(this.color)
        .borderRadius(2)
      Text(this.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#111827')
      Text(this.desc)
        .fontSize(10)
        .fontColor('#9CA3AF')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .onClick(() => {
      this.onTap();
    })
  }
}

@Entry
@Component
struct Index {
  @State resumes: Resume[] = [];
  @State tasks: PlanTask[] = [];

  aboutToAppear(): void {
    this.reload();
  }

  onPageShow(): void {
    this.reload();
  }

  private reload(): void {
    this.resumes = LocalStore.loadResumes();
    this.tasks = LocalStore.loadTasks();
  }

  private todayLabel(): string {
    const now: Date = new Date();
    const weeks: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    return (now.getMonth() + 1).toString() + ' 月 ' + now.getDate().toString() +
      ' 日 · 周' + weeks[now.getDay()];
  }

  private avgScore(): number {
    if (this.resumes.length === 0) {
      return 0;
    }
    let total: number = 0;
    for (let i = 0; i < this.resumes.length; i++) {
      total += this.scoreOf(this.resumes[i]);
    }
    return Math.round(total / this.resumes.length);
  }

  private scoreOf(resume: Resume): number {
    const template: TemplateDef | undefined = ConfigService.getTemplate(resume.templateId);
    const scene: string = template === undefined ? 'internet_intern' : template.scene;
    return DiagnosisService.quickScore(resume, scene);
  }

  private scoreColor(score: number): string {
    if (score >= 80) {
      return '#16A34A';
    }
    if (score >= 60) {
      return '#F59E0B';
    }
    return '#EF4444';
  }

  private heroTip(): string {
    if (this.resumes.length === 0) {
      return '创建第一份简历，开始你的求职准备';
    }
    const score: number = this.avgScore();
    if (score >= 80) {
      return '材料已比较完整，继续打磨描述细节';
    }
    if (score >= 60) {
      return '基础不错，还有几处明显缺口';
    }
    return '简历还有较大提升空间，先补关键项';
  }

  private templateName(resume: Resume): string {
    const template: TemplateDef | undefined = ConfigService.getTemplate(resume.templateId);
    return template === undefined ? '通用模板' : template.name;
  }

  private pendingTasks(): PlanTask[] {
    const list: PlanTask[] = [];
    for (let i = 0; i < this.tasks.length; i++) {
      if (!this.tasks[i].done) {
        list.push(this.tasks[i]);
      }
    }
    list.sort((a: PlanTask, b: PlanTask): number => {
      if (a.due === b.due) {
        return 0;
      }
      return a.due < b.due ? -1 : 1;
    });
    return list;
  }

  private previewTasks(): PlanTask[] {
    const list: PlanTask[] = this.pendingTasks();
    if (list.length > 3) {
      return list.slice(0, 3);
    }
    return list;
  }

  private pendingCount(): number {
    return this.pendingTasks().length;
  }

  private nearestDue(): string {
    const list: PlanTask[] = this.pendingTasks();
    return list.length === 0 ? '暂无' : list[0].due;
  }

  private latestResume(): Resume | undefined {
    return this.resumes.length === 0 ? undefined : this.resumes[0];
  }

  private gapList(): DiagItem[] {
    const latest: Resume | undefined = this.latestResume();
    if (latest === undefined) {
      return [];
    }
    const template: TemplateDef | undefined = ConfigService.getTemplate(latest.templateId);
    const scene: string = template === undefined ? 'internet_intern' : template.scene;
    const report: DiagReport = DiagnosisService.run(latest, scene, this.tasks);
    const gaps: DiagItem[] = report.gaps;
    return gaps.length > 3 ? gaps.slice(0, 3) : gaps;
  }

  private toggleTask(task: PlanTask, checked: boolean): void {
    task.done = checked;
    LocalStore.saveTasks(this.tasks);
    this.reload();
  }

  private loadSample(): void {
    const sample: Resume = SampleData.createResume();
    LocalStore.upsertResume(sample);
    this.reload();
    promptAction.showToast({ message: '示例简历已载入' });
  }

  private confirmDelete(resume: Resume): void {
    AlertDialog.show({
      title: '删除简历',
      message: '删除后无法恢复，确定删除「' + resume.title + '」吗？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#EF4444',
        action: () => {
          LocalStore.deleteResume(resume.id);
          this.reload();
          promptAction.showToast({ message: '已删除' });
        }
      }
    });
  }

  @Builder
  resumeRow(resume: Resume) {
    Row({ space: 10 }) {
      Column({ space: 4 }) {
        Text(resume.title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.templateName(resume) + ' · ' + formatTime(resume.updatedAt))
          .fontSize(10)
          .fontColor('#9CA3AF')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(this.scoreOf(resume).toString())
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.scoreColor(this.scoreOf(resume)))

      Text('编辑')
        .fontSize(11)
        .fontColor('#2563EB')
        .padding({ left: 6, right: 6, top: 5, bottom: 5 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/ResumeEdit', params: { id: resume.id } });
        })
      Text('删除')
        .fontSize(11)
        .fontColor('#B0B4BC')
        .padding({ left: 2, right: 2, top: 5, bottom: 5 })
        .onClick(() => {
          this.confirmDelete(resume);
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  taskRow(task: PlanTask) {
    Row({ space: 10 }) {
      Checkbox({ name: task.id, group: 'home_plan' })
        .select(task.done)
        .width(20)
        .height(20)
        .selectedColor('#2563EB')
        .onChange((checked: boolean) => {
          this.toggleTask(task, checked);
        })
      Column({ space: 3 }) {
        Text(task.title)
          .fontSize(13)
          .fontColor('#111827')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('截止 ' + task.due + (task.priority === 'high' ? ' · 紧急' : ''))
          .fontSize(10)
          .fontColor(task.priority === 'high' ? '#DC2626' : '#9CA3AF')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('›')
        .fontSize(18)
        .fontColor('#C4C8CE')
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 11, bottom: 11 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      router.pushUrl({ url: 'pages/Plan' });
    })
  }

  @Builder
  gapRow(item: DiagItem, index: number) {
    Row({ space: 10 }) {
      Text((index + 1).toString())
        .fontSize(11)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(20)
        .height(20)
        .backgroundColor(item.level === 'short' ? '#EF4444' : '#F59E0B')
        .borderRadius(10)
      Column({ space: 3 }) {
        Text(item.title)
          .fontSize(13)
          .fontColor('#111827')
        Text(item.actual)
          .fontSize(10)
          .fontColor('#9CA3AF')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('-' + item.weight.toString())
        .fontSize(12)
        .fontColor('#EF4444')
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 11, bottom: 11 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      const latest: Resume | undefined = this.latestResume();
      if (latest !== undefined) {
        router.pushUrl({ url: 'pages/Diagnosis', params: { id: latest.id } });
      }
    })
  }

  @Builder
  emptyResume() {
    Column({ space: 10 }) {
      Text('还没有简历')
        .fontSize(14)
        .fontColor('#374151')
      Text('选一套模板开始填写，填完即可一键诊断缺项。')
        .fontSize(11)
        .fontColor('#9CA3AF')
      Row({ space: 10 }) {
        Text('新建简历')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({ left: 16, right: 16, top: 7, bottom: 7 })
          .backgroundColor('#2563EB')
          .borderRadius(16)
          .onClick(() => {
            router.pushUrl({ url: 'pages/TemplatePick' });
          })
        Text('载入示例')
          .fontSize(12)
          .fontColor('#374151')
          .padding({ left: 16, right: 16, top: 7, bottom: 7 })
          .backgroundColor('#F3F4F6')
          .borderRadius(16)
          .onClick(() => {
            this.loadSample();
          })
      }
    }
    .width('100%')
    .padding({ top: 22, bottom: 22 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  build() {
    Column() {
      Row() {
        Column({ space: 3 }) {
          Text(this.todayLabel())
            .fontSize(11)
            .fontColor('#9CA3AF')
          Text('简途')
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor('#111827')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('设置')
          .fontSize(12)
          .fontColor('#374151')
          .padding({ left: 12, right: 12, top: 7, bottom: 7 })
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .onClick(() => {
            router.pushUrl({ url: 'pages/Settings' });
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 14, bottom: 10 })

      Scroll() {
        Column({ space: 12 }) {
          Column() {
            Row() {
              Column({ space: 4 }) {
                Text('求职准备度')
                  .fontSize(12)
                  .fontColor('#DBEAFE')
                Row({ space: 4 }) {
                  Text(this.avgScore().toString())
                    .fontSize(42)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                  Text('分')
                    .fontSize(12)
                    .fontColor('#DBEAFE')
                    .margin({ bottom: 6 })
                }
                Text(this.heroTip())
                  .fontSize(11)
                  .fontColor('#DBEAFE')
                  .maxLines(2)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Progress({ value: this.avgScore(), total: 100, type: ProgressType.Ring })
                .width(76)
                .height(76)
                .color('#FFFFFF')
                .style({ strokeWidth: 8 })
            }
            .width('100%')

            Divider()
              .color('#40FFFFFF')
              .margin({ top: 14, bottom: 12 })

            Row() {
              Column({ space: 3 }) {
                Text(this.resumes.length.toString())
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('份简历')
                  .fontSize(10)
                  .fontColor('#DBEAFE')
              }
              .layoutWeight(1)
              Column({ space: 3 }) {
                Text(this.pendingCount().toString())
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('项待办')
                  .fontSize(10)
                  .fontColor('#DBEAFE')
              }
              .layoutWeight(1)
              Column({ space: 3 }) {
                Text(this.nearestDue())
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFFFFF')
                Text('最近截止')
                  .fontSize(10)
                  .fontColor('#DBEAFE')
              }
              .layoutWeight(1.4)
              .alignItems(HorizontalAlign.End)
            }
            .width('100%')

            Text(this.resumes.length === 0 ? '开始第一份简历' : '新建一份简历')
              .fontSize(12)
              .fontColor('#1D4ED8')
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              .backgroundColor('#FFFFFF')
              .borderRadius(10)
              .margin({ top: 14 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/TemplatePick' });
              })
          }
          .width('100%')
          .padding(18)
          .borderRadius(18)
          .linearGradient({
            angle: 135,
            colors: [['#2563EB', 0.0], ['#7C3AED', 1.0]]
          })

          Text('快捷操作')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111827')
            .width('100%')
            .margin({ top: 4 })

          Row({ space: 10 }) {
            QuickAction({
              title: '新建简历',
              desc: '选模板，逐项填写',
              color: '#2563EB',
              onTap: () => {
                router.pushUrl({ url: 'pages/TemplatePick' });
              }
            })
              .layoutWeight(1)
            QuickAction({
              title: '一键诊断',
              desc: '找出缺项与扣分点',
              color: '#7C3AED',
              onTap: () => {
                const latest: Resume | undefined = this.latestResume();
                if (latest === undefined) {
                  router.pushUrl({ url: 'pages/TemplatePick' });
                } else {
                  router.pushUrl({ url: 'pages/Diagnosis', params: { id: latest.id } });
                }
              }
            })
              .layoutWeight(1)
          }
          .width('100%')

          Row({ space: 10 }) {
            QuickAction({
              title: '成长计划',
              desc: '按缺口生成任务',
              color: '#0F766E',
              onTap: () => {
                router.pushUrl({ url: 'pages/Plan' });
              }
            })
              .layoutWeight(1)
            QuickAction({
              title: '数据备份',
              desc: '导出或导入 JSON',
              color: '#D97706',
              onTap: () => {
                router.pushUrl({ url: 'pages/Settings' });
              }
            })
              .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Text('最近简历')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#111827')
            Blank()
            Text(this.resumes.length.toString() + ' 份')
              .fontSize(11)
              .fontColor('#9CA3AF')
          }
          .width('100%')
          .margin({ top: 4 })

          if (this.resumes.length === 0) {
            this.emptyResume()
          } else {
            ForEach(this.resumes.slice(0, 3), (resume: Resume) => {
              this.resumeRow(resume)
            }, (resume: Resume) => resume.id)
          }

          Row() {
            Text('待办提醒')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#111827')
            Blank()
            Text('查看全部')
              .fontSize(11)
              .fontColor('#2563EB')
              .onClick(() => {
                router.pushUrl({ url: 'pages/Plan' });
              })
          }
          .width('100%')
          .margin({ top: 4 })

          if (this.previewTasks().length === 0) {
            Row() {
              Text('暂无待办，去诊断页生成成长计划')
                .fontSize(11)
                .fontColor('#9CA3AF')
            }
            .width('100%')
            .padding(14)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
          } else {
            ForEach(this.previewTasks(), (task: PlanTask) => {
              this.taskRow(task)
            }, (task: PlanTask) => task.id)
          }

          if (this.gapList().length > 0) {
            Row() {
              Text('优先补齐')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111827')
              Blank()
              Text('完整报告')
                .fontSize(11)
                .fontColor('#7C3AED')
                .onClick(() => {
                  const latest: Resume | undefined = this.latestResume();
                  if (latest !== undefined) {
                    router.pushUrl({ url: 'pages/Diagnosis', params: { id: latest.id } });
                  }
                })
            }
            .width('100%')
            .margin({ top: 4 })

            ForEach(this.gapList(), (item: DiagItem, index: number) => {
              this.gapRow(item, index)
            }, (item: DiagItem) => item.ruleId)
          }

          Row() {
            Text('全部数据仅保存在本机')
              .fontSize(10)
              .fontColor('#B0B4BC')
            Blank()
            Text('离线运行')
              .fontSize(10)
              .fontColor('#B0B4BC')
          }
          .width('100%')
          .margin({ top: 8, bottom: 24 })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
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
