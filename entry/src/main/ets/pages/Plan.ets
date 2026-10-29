import { promptAction, router } from '@kit.ArkUI';
import { addDays, newId, PlanTask } from '../model/Models';
import { LocalStore } from '../service/LocalStore';

@Entry
@Component
struct Plan {
  @State tasks: PlanTask[] = [];
  @State showAdd: boolean = false;
  @State newTitle: string = '';
  @State newDue: string = '';
  @State newPriority: string = 'medium';
  @State editingId: string = '';
  @State editDue: string = '';
  @State editPriority: string = 'medium';
  @State loaded: boolean = false;

  aboutToAppear(): void {
    this.reload();
    this.newDue = addDays(30);
    this.loaded = true;
  }

  onPageShow(): void {
    if (this.loaded) {
      this.reload();
    }
  }

  private reload(): void {
    this.tasks = LocalStore.loadTasks();
    this.tasks = this.sorted();
  }

  private sorted(): PlanTask[] {
    const list: PlanTask[] = this.tasks.slice();
    list.sort((a: PlanTask, b: PlanTask): number => {
      if (a.done !== b.done) {
        return a.done ? 1 : -1;
      }
      if (a.due !== b.due) {
        return a.due < b.due ? -1 : 1;
      }
      return 0;
    });
    return list;
  }

  private doneCount(): number {
    let count: number = 0;
    for (let i = 0; i < this.tasks.length; i++) {
      if (this.tasks[i].done) {
        count++;
      }
    }
    return count;
  }

  private toggle(task: PlanTask, checked: boolean): void {
    task.done = checked;
    const list: PlanTask[] = this.tasks.slice();
    LocalStore.saveTasks(list);
    this.tasks = this.sorted();
  }

  private removeTask(id: string): void {
    const list: PlanTask[] = this.tasks.filter((task: PlanTask) => task.id !== id);
    LocalStore.saveTasks(list);
    this.tasks = this.sorted();
  }

  private addTask(): void {
    if (this.newTitle.trim().length === 0) {
      promptAction.showToast({ message: '请输入任务标题' });
      return;
    }
    const task: PlanTask = {
      id: newId('task'),
      title: this.newTitle.trim(),
      detail: '',
      due: this.newDue.trim().length > 0 ? this.newDue.trim() : addDays(30),
      priority: this.newPriority,
      done: false,
      ruleId: '',
      createdAt: Date.now()
    };
    this.tasks = this.tasks.concat([task]);
    LocalStore.saveTasks(this.tasks);
    this.newTitle = '';
    this.newDue = addDays(30);
    this.newPriority = 'medium';
    this.showAdd = false;
    this.tasks = this.sorted();
    promptAction.showToast({ message: '已添加' });
  }

  private clearDone(): void {
    const list: PlanTask[] = this.tasks.filter((task: PlanTask) => !task.done);
    LocalStore.saveTasks(list);
    this.tasks = list;
  }

  private priorityLabel(priority: string): string {
    if (priority === 'high') {
      return '紧急';
    }
    if (priority === 'low') {
      return '普通';
    }
    return '重要';
  }

  private priorityColor(priority: string): string {
    if (priority === 'high') {
      return '#DC2626';
    }
    if (priority === 'low') {
      return '#6B7280';
    }
    return '#D97706';
  }

  private priorityBg(priority: string): string {
    if (priority === 'high') {
      return '#FEE2E2';
    }
    if (priority === 'low') {
      return '#F3F4F6';
    }
    return '#FEF3C7';
  }

  private pendingTasks(): PlanTask[] {
    const list: PlanTask[] = [];
    const sorted: PlanTask[] = this.sorted();
    for (let i = 0; i < sorted.length; i++) {
      if (!sorted[i].done) {
        list.push(sorted[i]);
      }
    }
    return list;
  }

  private finishedTasks(): PlanTask[] {
    const list: PlanTask[] = [];
    const sorted: PlanTask[] = this.sorted();
    for (let i = 0; i < sorted.length; i++) {
      if (sorted[i].done) {
        list.push(sorted[i]);
      }
    }
    return list;
  }

  private startEdit(task: PlanTask): void {
    this.editingId = task.id;
    this.editDue = task.due;
    this.editPriority = task.priority;
  }

  private saveEdit(): void {
    for (let i = 0; i < this.tasks.length; i++) {
      if (this.tasks[i].id === this.editingId) {
        if (this.editDue.trim().length > 0) {
          this.tasks[i].due = this.editDue.trim();
        }
        this.tasks[i].priority = this.editPriority;
        break;
      }
    }
    LocalStore.saveTasks(this.tasks);
    this.editingId = '';
    this.tasks = this.sorted();
    promptAction.showToast({ message: '已更新' });
  }

  @Builder
  taskRow(task: PlanTask) {
    Row({ space: 10 }) {
      Checkbox({ name: task.id, group: 'plan' })
        .select(task.done)
        .width(20)
        .height(20)
        .selectedColor('#2563EB')
        .onChange((checked: boolean) => {
          this.toggle(task, checked);
        })

      Column({ space: 5 }) {
        Text(task.title)
          .fontSize(14)
          .fontColor(task.done ? '#9CA3AF' : '#111827')
          .decoration({ type: task.done ? TextDecorationType.LineThrough : TextDecorationType.None })
          .width('100%')
        Row({ space: 6 }) {
          Text(this.priorityLabel(task.priority))
            .fontSize(9)
            .fontColor(this.priorityColor(task.priority))
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .backgroundColor(this.priorityBg(task.priority))
            .borderRadius(4)
          Text('截止 ' + task.due)
            .fontSize(10)
            .fontColor('#9CA3AF')
          if (task.ruleId.length > 0) {
            Text('来自诊断')
              .fontSize(9)
              .fontColor('#2563EB')
          }
        }
        .width('100%')

        if (task.detail.length > 0) {
          Text(task.detail)
            .fontSize(11)
            .fontColor('#6B7280')
            .lineHeight(17)
            .width('100%')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('调整')
        .fontSize(10)
        .fontColor('#6B7280')
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
        .onClick(() => {
          this.startEdit(task);
        })
      Text('×')
        .fontSize(18)
        .fontColor('#C4C8CE')
        .width(24)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.removeTask(task.id);
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 10 })
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
        Text('成长计划')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
        Blank()
        Text('+ 新任务')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#2563EB')
          .borderRadius(14)
          .onClick(() => {
            this.showAdd = !this.showAdd;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 10 })

      Scroll() {
        Column({ space: 10 }) {
          if (this.showAdd) {
            Column({ space: 10 }) {
              TextInput({ text: this.newTitle, placeholder: '任务标题，例如：完成一个鸿蒙开源项目' })
                .height(42)
                .fontSize(14)
                .backgroundColor('#F7F8FA')
                .borderRadius(8)
                .onChange((value: string) => {
                  this.newTitle = value;
                })
              Row({ space: 8 }) {
                Text('截止日期')
                  .fontSize(12)
                  .fontColor('#6B7280')
                TextInput({ text: this.newDue, placeholder: '2026-12-31' })
                  .layoutWeight(1)
                  .height(38)
                  .fontSize(13)
                  .backgroundColor('#F7F8FA')
                  .borderRadius(8)
                  .onChange((value: string) => {
                    this.newDue = value;
                  })
              }
              .width('100%')
              Row({ space: 8 }) {
                Text('优先级')
                  .fontSize(12)
                  .fontColor('#6B7280')
                Text('紧急')
                  .fontSize(12)
                  .fontColor(this.newPriority === 'high' ? '#FFFFFF' : '#4B5563')
                  .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                  .backgroundColor(this.newPriority === 'high' ? '#DC2626' : '#F3F4F6')
                  .borderRadius(14)
                  .onClick(() => {
                    this.newPriority = 'high';
                  })
                Text('重要')
                  .fontSize(12)
                  .fontColor(this.newPriority === 'medium' ? '#FFFFFF' : '#4B5563')
                  .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                  .backgroundColor(this.newPriority === 'medium' ? '#D97706' : '#F3F4F6')
                  .borderRadius(14)
                  .onClick(() => {
                    this.newPriority = 'medium';
                  })
                Text('普通')
                  .fontSize(12)
                  .fontColor(this.newPriority === 'low' ? '#FFFFFF' : '#4B5563')
                  .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                  .backgroundColor(this.newPriority === 'low' ? '#6B7280' : '#F3F4F6')
                  .borderRadius(14)
                  .onClick(() => {
                    this.newPriority = 'low';
                  })
              }
              .width('100%')
              Row({ space: 10 }) {
                Text('取消')
                  .fontSize(13)
                  .fontColor('#6B7280')
                  .textAlign(TextAlign.Center)
                  .layoutWeight(1)
                  .padding({ top: 9, bottom: 9 })
                  .backgroundColor('#F3F4F6')
                  .borderRadius(8)
                  .onClick(() => {
                    this.showAdd = false;
                  })
                Text('添加')
                  .fontSize(13)
                  .fontColor('#FFFFFF')
                  .textAlign(TextAlign.Center)
                  .layoutWeight(1)
                  .padding({ top: 9, bottom: 9 })
                  .backgroundColor('#2563EB')
                  .borderRadius(8)
                  .onClick(() => {
                    this.addTask();
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
          }

          if (this.editingId.length > 0) {
            Column({ space: 10 }) {
              Text('调整任务')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#111827')
                .width('100%')
              Row({ space: 8 }) {
                Text('截止日期')
                  .fontSize(12)
                  .fontColor('#6B7280')
                TextInput({ text: this.editDue, placeholder: '2026-12-31' })
                  .layoutWeight(1)
                  .height(38)
                  .fontSize(13)
                  .backgroundColor('#F7F8FA')
                  .borderRadius(8)
                  .onChange((value: string) => {
                    this.editDue = value;
                  })
              }
              .width('100%')
              Row({ space: 8 }) {
                Text('优先级')
                  .fontSize(12)
                  .fontColor('#6B7280')
                Text('紧急')
                  .fontSize(12)
                  .fontColor(this.editPriority === 'high' ? '#FFFFFF' : '#4B5563')
                  .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                  .backgroundColor(this.editPriority === 'high' ? '#DC2626' : '#F3F4F6')
                  .borderRadius(14)
                  .onClick(() => {
                    this.editPriority = 'high';
                  })
                Text('重要')
                  .fontSize(12)
                  .fontColor(this.editPriority === 'medium' ? '#FFFFFF' : '#4B5563')
                  .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                  .backgroundColor(this.editPriority === 'medium' ? '#D97706' : '#F3F4F6')
                  .borderRadius(14)
                  .onClick(() => {
                    this.editPriority = 'medium';
                  })
                Text('普通')
                  .fontSize(12)
                  .fontColor(this.editPriority === 'low' ? '#FFFFFF' : '#4B5563')
                  .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                  .backgroundColor(this.editPriority === 'low' ? '#6B7280' : '#F3F4F6')
                  .borderRadius(14)
                  .onClick(() => {
                    this.editPriority = 'low';
                  })
              }
              .width('100%')
              Row({ space: 10 }) {
                Text('取消')
                  .fontSize(13)
                  .fontColor('#6B7280')
                  .textAlign(TextAlign.Center)
                  .layoutWeight(1)
                  .padding({ top: 9, bottom: 9 })
                  .backgroundColor('#F3F4F6')
                  .borderRadius(8)
                  .onClick(() => {
                    this.editingId = '';
                  })
                Text('保存调整')
                  .fontSize(13)
                  .fontColor('#FFFFFF')
                  .textAlign(TextAlign.Center)
                  .layoutWeight(1)
                  .padding({ top: 9, bottom: 9 })
                  .backgroundColor('#2563EB')
                  .borderRadius(8)
                  .onClick(() => {
                    this.saveEdit();
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
          }

          Column({ space: 8 }) {
            Row() {
              Text('完成进度')
                .fontSize(12)
                .fontColor('#6B7280')
              Blank()
              Text(this.doneCount().toString() + ' / ' + this.tasks.length.toString())
                .fontSize(12)
                .fontColor('#111827')
            }
            .width('100%')
            Progress({
              value: this.doneCount(),
              total: this.tasks.length > 0 ? this.tasks.length : 1,
              type: ProgressType.Linear
            })
              .width('100%')
              .height(8)
              .color('#16A34A')
              .backgroundColor('#F3F4F6')
            Text('勾选完成的任务会同步提升简历诊断分（最多 +10 分）')
              .fontSize(10)
              .fontColor('#9CA3AF')
              .width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)

          Row() {
            Text('待办清单')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#111827')
            Blank()
            if (this.doneCount() > 0) {
              Text('清除已完成')
                .fontSize(11)
                .fontColor('#9CA3AF')
                .onClick(() => {
                  this.clearDone();
                })
            }
          }
          .width('100%')
          .margin({ top: 4 })

          if (this.tasks.length === 0) {
            Column({ space: 8 }) {
              Text('还没有成长任务')
                .fontSize(14)
                .fontColor('#374151')
              Text('去简历诊断页点击「生成成长计划」，系统会按缺口自动建任务。')
                .fontSize(11)
                .fontColor('#9CA3AF')
                .textAlign(TextAlign.Center)
                .width('90%')
            }
            .width('100%')
            .padding({ top: 28, bottom: 28 })
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
          } else {
            Row() {
              Text('待完成')
                .fontSize(12)
                .fontColor('#6B7280')
              Blank()
              Text(this.pendingTasks().length.toString() + ' 项')
                .fontSize(11)
                .fontColor('#9CA3AF')
            }
            .width('100%')
            .margin({ top: 4 })

            ForEach(this.pendingTasks(), (task: PlanTask) => {
              this.taskRow(task)
            }, (task: PlanTask) => task.id + '_todo')

            if (this.finishedTasks().length > 0) {
              Row() {
                Text('已完成')
                  .fontSize(12)
                  .fontColor('#6B7280')
                Blank()
                Text(this.finishedTasks().length.toString() + ' 项')
                  .fontSize(11)
                  .fontColor('#9CA3AF')
              }
              .width('100%')
              .margin({ top: 6 })

              ForEach(this.finishedTasks(), (task: PlanTask) => {
                this.taskRow(task)
              }, (task: PlanTask) => task.id + '_done')
            }
          }

          Text('所有数据仅保存在本机')
            .fontSize(11)
            .fontColor('#B0B4BC')
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
