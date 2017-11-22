; RUN: opt < %s  -loop-vectorize -force-vector-width=4 -S | FileCheck %s

target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

@a = local_unnamed_addr global [100000 x i32] zeroinitializer, align 16
@b = local_unnamed_addr global [100000 x i32] zeroinitializer, align 16
@c = local_unnamed_addr global [100000 x i32] zeroinitializer, align 16

; CHECK-LABEL: @main(
; CHECK: add nsw <4 x i32>
; Function Attrs: norecurse nounwind uwtable
define i32 @main(i32 %argc, i8** nocapture readnone %argv) local_unnamed_addr #0 {
entry:
  %syncreg = tail call token @llvm.syncregion.start()
  br label %pfor.detach

pfor.cond.cleanup:                                ; preds = %pfor.inc
  sync within %syncreg, label %pfor.end.continue

pfor.end.continue:                                ; preds = %pfor.cond.cleanup
  ret i32 0

pfor.detach:                                      ; preds = %pfor.inc, %entry
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %pfor.inc ]
  detach within %syncreg, label %pfor.body, label %pfor.inc

pfor.body:                                        ; preds = %pfor.detach
  %arrayidx = getelementptr inbounds [100000 x i32], [100000 x i32]* @a, i64 0, i64 %indvars.iv
  %0 = load i32, i32* %arrayidx, align 4, !tbaa !2
  %arrayidx2 = getelementptr inbounds [100000 x i32], [100000 x i32]* @b, i64 0, i64 %indvars.iv
  %1 = load i32, i32* %arrayidx2, align 4, !tbaa !2
  %add3 = add nsw i32 %1, %0
  %arrayidx5 = getelementptr inbounds [100000 x i32], [100000 x i32]* @c, i64 0, i64 %indvars.iv
  store i32 %add3, i32* %arrayidx5, align 4, !tbaa !2
  reattach within %syncreg, label %pfor.inc

pfor.inc:                                         ; preds = %pfor.body, %pfor.detach
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, 100000
  br i1 %exitcond, label %pfor.cond.cleanup, label %pfor.detach, !llvm.loop !6
}

; Function Attrs: argmemonly nounwind
declare token @llvm.syncregion.start() #1

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 5.0.0 (https://github.com/wsmoses/Cilk-Clang.git eaf246ef85cae33736dc7b015af97267045a6230) (git@github.com:wsmoses/Parallel-IR.git ca578abf2ded623076a35ebe6dd37816c0c41ede)"}
!2 = !{!3, !3, i64 0}
!3 = !{!"int", !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C++ TBAA"}
!6 = distinct !{!6, !7}
!7 = !{!"tapir.loop.spawn.strategy", i32 1}
