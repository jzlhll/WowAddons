local _, addon = ... ; addon = addon or {}

--[[--
创建一个类
~~~ lua

-- 定义名为 Shape 的基础类
local Shape = class("Shape")

-- ctor() 是类的构造函数，在调用 Shape.new() 创建 Shape 对象实例时会自动执行
function Shape:ctor(shapeName)
    self.shapeName = shapeName
    printf("Shape:ctor(%s)", self.shapeName)
end

-- 为 Shape 定义个名为 draw() 的方法
function Shape:draw()
    printf("draw %s", self.shapeName)
end

--

-- Circle 是 Shape 的继承类
local Circle = class("Circle", Shape)

function Circle:ctor()
    -- 如果继承类覆盖了 ctor() 构造函数，那么必须手动调用父类构造函数
    -- 类名.super 可以访问指定类的父类
    Circle.super.ctor(self, "circle")
    self.radius = 100
end

function Circle:setRadius(radius)
    self.radius = radius
end

-- 覆盖父类的同名方法
function Circle:draw()
    printf("draw %s, raidus = %0.2f", self.shapeName, self.raidus)
end

--

local Rectangle = class("Rectangle", Shape)

function Rectangle:ctor()
    Rectangle.super.ctor(self, "rectangle")
end

--

local circle = Circle.new()             -- 输出: Shape:ctor(circle)
circle:setRaidus(200)
circle:draw()                           -- 输出: draw circle, radius = 200.00

local rectangle = Rectangle.new()       -- 输出: Shape:ctor(rectangle)
rectangle:draw()                        -- 输出: draw rectangle
]]
addon.class_newInstance = function(classname, super)
    local superType = type(super)
    local cls

    local fixSuperType = nil
    if superType ~= "function" and superType ~= "table" then
        fixSuperType = nil
        super = nil
    else
        fixSuperType = superType
    end

    if fixSuperType == "function" or (super and super.__ctype == 1) then
        -- inherited from native C++ Object
        cls = {}

        if fixSuperType == "table" then
            -- copy fields from super
            for k,v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
            cls.ctor = function() end
        end

        cls.__cname = classname
        cls.__ctype = 1

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k,v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end

    else
        -- inherited from Lua Object
        if super then
            cls = {}
            setmetatable(cls, {__index = super})
            cls.super = super
        else
            cls = {ctor = function() end}
        end

        cls.__cname = classname
        cls.__ctype = 2 -- lua
        cls.__index = cls

        function cls.new(...)
            local instance = setmetatable({}, cls)
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    end

    return cls
end