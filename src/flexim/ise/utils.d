/*
 * flexim/ise/utils.d
 * 
 * Copyright (c) 2010 Min Cai <itecgo@163.com>. 
 * 
 * This file is part of the Flexim multicore architectural simulator.
 * 
 * Flexim is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Flexim is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Flexim.  If not, see <http ://www.gnu.org/licenses/>.
 */

module flexim.ise.utils;

import flexim.all;

T getBuilderObject(T, K)(ObjectG obj) {
	obj.setData("GObject", null);
	return new T(cast(K*)obj.getObjectGStruct());
}

T getBuilderObject(T, K)(Builder builder, string name) {
	return getBuilderObject!(T, K)(builder.getObject(name));
}

void guiActionNotImplemented(Window parent, string text) {
	MessageDialog d = new MessageDialog(parent, GtkDialogFlags.MODAL, MessageType.INFO, ButtonsType.OK, text);
	d.run();
	d.destroy();
}

HBox hpack(T...)(T widgets) {
	HBox hbox = new HBox(false, 6);
	
	foreach(widget; widgets) {
		if(is(typeof(widget) == Label) || is(typeof(widget) == VSeparator)) {
			hbox.packStart(widget, false, false, 0);
		}
		else if(is(typeof(widget) == Entry)) {
			hbox.packStart(widget, true, true, 0);
		}
		else {
			hbox.packStart(widget, true, true, 0);
		}
	}
	
	return hbox;
}

VBox vpack(T...)(T widgets) {
	VBox vbox = new VBox(false, 6);
	
	foreach(widget; widgets) {
		vbox.packStart(widget, false, true, 0);
	}
	
	return vbox;
}

VBox vpack2(T)(T[] widgets) {
	VBox vbox = new VBox(false, 6);
	
	foreach(widget; widgets) {
		vbox.packStart(widget, false, true, 0);
	}
	
	return vbox;
}

HBox newHBoxWithLabelAndWidget(string labelText, Widget widget) {
	Label label = new Label("<b>" ~ labelText ~ "</b>");
	label.setUseMarkup(true);

	return hpack(label, widget);
}

HBox newHBoxWithLabelAndComboBox(string labelText, void delegate(ComboBox) comboBoxInitAction = null, void delegate() comboBoxChangedAction = null) {
	Label label = new Label("<b>" ~ labelText ~ "</b>");
	label.setUseMarkup(true);

	GType[] types;
	types ~= GType.STRING;
	
	ListStore listStore = new ListStore(types);
	
	ComboBox comboBox = new ComboBox(listStore);
	
	if(comboBoxInitAction !is null) {
		comboBoxInitAction(comboBox);
	}
	
	comboBox.addOnChanged(delegate void(ComboBox)
		{
			if(comboBoxChangedAction !is null) {
				comboBoxChangedAction();
			}
		});
	comboBox.setActive(0);
	
	comboBox.setSensitive(comboBoxChangedAction !is null);

	return hpack(label, comboBox);
}

HBox newHBoxWithLabelAndEntry(string labelText, string entryText, void delegate(string) entryChangedAction = null) {
	Label label = new Label("<b>" ~ labelText ~ "</b>");
	label.setUseMarkup(true);
	Entry entry = new Entry(entryText);
	entry.addOnChanged(delegate void(EditableIF)
		{
			if(entryChangedAction !is null) {
				entryChangedAction(entry.getText());
			}
		});

	entry.setEditable(entryChangedAction !is null);
	
	return hpack(label, entry);
}

HBox newHBoxWithLabelAndSpinButton(T)(string labelText, T minEntryValue, T maxEntryValue, T entryStep, T initialEntryValue, void delegate(T newText) spinButtonValueChangedAction = null) {
	Label label = new Label("<b>" ~ labelText ~ "</b>");
	label.setUseMarkup(true);
	SpinButton spinButton = new SpinButton(cast(double) minEntryValue, cast(double) maxEntryValue, entryStep);
	spinButton.setValue(cast(double) initialEntryValue);
	spinButton.setDigits(0);
	spinButton.addOnValueChanged(delegate void(SpinButton)
		{
			if(spinButtonValueChangedAction !is null) {
				spinButtonValueChangedAction(cast(T) (spinButton.getValue()));
			}
		});

	spinButton.setEditable(spinButtonValueChangedAction !is null);
	
	return hpack(label, spinButton);
}

void setupTextComboBox(ComboBox comboBox) {
	GType[] types;
	types ~= GType.STRING;
	
	ListStore listStore = new ListStore(types);
	
	comboBox.setModel(listStore);
	
	CellRenderer renderer = new CellRendererText();
	comboBox.packStart(renderer, true);
	comboBox.addAttribute(renderer, "text", 0);
}

string registerStockId(string name, string label, string key, string fileName = null) {
	if(fileName is null) {
		fileName = format("../gtk/stock/%s.svg", name);
	}
	string domain = "slow";
	string id = format("%s-%s", domain, name);
	Pixbuf pixbuf = new Pixbuf(fileName);
	IconSet iconSet = new IconSet(pixbuf);
	IconFactory factory = new IconFactory();
	factory.add(id, iconSet);
	factory.addDefault();
	int keyval = Keymap.gdkKeyvalFromName(key);
	GdkModifierType modifier = GdkModifierType.MOD1_MASK;
	
	GtkStockItem gtkStockItem;

	gtkStockItem.stockId = cast(char*) toStringz(id);
	gtkStockItem.label = cast(char*) toStringz(label);
	gtkStockItem.modifier = modifier;
	gtkStockItem.keyval = keyval;
	gtkStockItem.translationDomain = cast(char*) toStringz(domain);
	
	StockItem stockItem = new StockItem(&gtkStockItem);
	stockItem.add(1);
	
	return id;
}

ToolItemGroup addItemGroup(ToolPalette palette, string name) {
	ToolItemGroup group = new ToolItemGroup(name);
	palette.add(group);
	return group;
}

ToolItem addItem(ToolItemGroup group, string stockId, string actionName, string tooltipText) {
	ToolButton item = new ToolButton(stockId);
	item.setActionName(actionName);
	item.setTooltipText(tooltipText);
	item.setIsImportant(true);
	group.insert(item, -1);
	return item;
}

ToolButton bindToolButton(ToolButton toolButton, void delegate() action) {
	toolButton.addOnClicked(delegate void(ToolButton toolButton)
		{
			action();
		});
	return toolButton;
}

ToolButton bindToolButton(Builder builder, string toolButtonName, void delegate() action) {
	ToolButton toolButton = getBuilderObject!(ToolButton, GtkToolButton)(builder, toolButtonName);
	return bindToolButton(toolButton, action);
}

MenuItem bindMenuItem(MenuItem menuItem, void delegate() action) {
	menuItem.addOnActivate(delegate void(MenuItem)
		{
			action();
		});
	return menuItem;
}

MenuItem bindMenuItem(Builder builder, string menuItemName, void delegate() action) {
	MenuItem menuItem = getBuilderObject!(ImageMenuItem, GtkImageMenuItem)(builder, menuItemName);
	return bindMenuItem(menuItem, action);
}

void hideOnDelete(Dialog dialog) {
	dialog.addOnDelete(delegate bool(gdk.Event.Event, Widget)
		{
			dialog.hide();
			return true;
		});
}