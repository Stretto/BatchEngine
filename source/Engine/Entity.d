module Engine.Entity;

import Engine.Component;
import t = Engine.Transform;
import Engine.Core;
import Engine.Coroutine;
import std.stdio;
import Engine.Sprite;
import Engine.util;
import Engine.CStorage;
import std.bitmanip;

class Entity
{
	package Component[] components;
	package t.Transform transform_;
	package ptrdiff_t arrayIndex;
	BitArray componentsBits;
	bool active;
	Sprite sprite;
	string name;
	bool valid;
	
	@property package bool inScene() {
		return arrayIndex >= 0;
	};
	
	this(bool addTransform = true)
	{
		components = new Component[5];
		components.length = 0;
		componentsBits.length = ComponentStorage.bitCounter+1;
		if (addTransform)
			AddComponent!(t.Transform)();
		active = true;
		valid = true;
		arrayIndex = -1;
	}

	final @property t.Transform transform() { return transform_; }

	final @property public auto Components() {
		return ConstArray!Component(components);	
	};
	
	public auto AddComponent(T, Args...)(Args args)  {
		auto t = StorageImpl!(T).allocate(args);
		components ~= new Component(t);
		StorageImpl!(T).Bind(t,this);	
		return t;	
	}	
	
	public auto AddComponent()(Component component)  {
		components ~= component;
		component.storage.Bind(component.component,this);
		return component;
	}	

	public auto AddComponent(T)(T component) if (!is(T == Component))  {
		auto c = new Component(component);
		components ~= c;
		c.storage.Bind(c.component,this);
		return component;
	}

	public T GetComponent(T)() {
		foreach( c; components) {
			T t = c.Cast!T();
			if (t !is null) {
				return t;
			}
		}
		return null;
	}
	
	public Component GetComponent()(Component component)  {
		foreach( c; components) {
			if (component.component == c.component)
				return c;
		}	
		return null;
	}	

	public Entity Clone()
	{		
		Entity t = new Entity(false);
		foreach (ref c ; this.components) {
			t.AddComponent(c.Clone());
		}
		return t;
	}

	public void Destory()
	{
		if (!valid)
			return;
		Core.RemoveEntity(this);
		foreach( c; components) {	
			c.storage.Remove(c.component);
		}
		components = null;
		active = false;
		valid = false;
	}

	package void onActive() {
		foreach( c; components) {
			c.storage.Active(c.component);
		}
	}
	

	public bool RemoveComponent()(Component component) {
		for (int i=0;i<components.length;i++) {
			if (component.component == components[i].component) {
				components[i] = components[components.length-1];
				components.length--;
				return true;
			}
		}
		return false;
	}

	public bool RemoveComponent(T)() {
		for (int i=0;i<components.length;i++) {
			if (components[i].Cast!T() !is null) {
				components[i] = components[components.length-1];
				components.length--;
				return true;
			}
		}
		return false;
	}
}


