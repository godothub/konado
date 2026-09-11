# 示例 08｜异步运镜但机位不存在
# 期望：CA-001 camera.move_rejected → KonadoInstructionExecutor._camera_move_async
# 排错：在场景里放置同名 Marker2D/机位节点，或先把相机控制器绑定到 KonadoDialogue。
#      没有相机控制器时会改报 RT-001 runtime.controller_missing。
asyncam move nowhere linear 1.0
end
