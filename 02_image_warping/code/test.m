% 创建一个图形窗口
f = figure;
% 创建一个按钮
b = uicontrol(f,'Style','pushbutton','String','Say Hello',...
    'Position',[100 100 100 50]);
% 创建一个文本框
t = uicontrol(f,'Style','text','String','',...
    'Position',[100 200 100 50]);
% 定义一个回调函数
function sayHello(src,event)
    % 在文本框中显示“Hello World”
    t.String = 'Hello World';
end
% 将回调函数赋给按钮的Callback属性
b.Callback = @sayHello;