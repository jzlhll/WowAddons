开发指南
新建模块到子目录：
1. 开头添加  local _, addon = ...
2. 如果需要later|later2初始化，则末尾注册事件监听：addon:registGlobalEvent(receiveMainMsg)
3. 如果需要插件配置选项，则添加addon:registCategoryCreator(function() xxx end)
    addon:initCategoryCheckBox(title, initChecked, changeCheckFun)
    addon.initCategoryButton
    addon:initCategoryCheckBoxes
