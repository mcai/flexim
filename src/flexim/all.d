/*
 * flexim/all.d
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

module flexim.all;

public import std.algorithm;
public import std.array;
public import std.container;
public import std.conv;
public import std.math;
public import std.random;
public import std.stdio;
public import std.string;
public import std.typecons;
 
public import cairo.ImageSurface;
public import cairo.PdfSurface;
public import cairo.Surface;

public import gdk.Color;
public import gdk.Cursor;
public import gdk.Display;
public import gdk.Drawable;
public import gdk.Event;
public import gdk.Keymap;
public import gdk.Keysyms;
public import gdk.Pixbuf;
public import gdk.Rectangle;
public import gdk.Screen;

public import glade.Glade;

public import glib.RandG;

public import gobject.ObjectG;
public import gobject.Value;

public import gtk.AboutDialog;
public import gtk.Builder;
public import gtk.Button;
public import gtk.CellRenderer;
public import gtk.CellRendererCombo;
public import gtk.CellRendererPixbuf;
public import gtk.CellRendererText;
public import gtk.CheckButton;
public import gtk.ComboBox;
public import gtk.Dialog;
public import gtk.DragAndDrop;
public import gtk.DrawingArea;
public import gtk.EditableIF;
public import gtk.Entry;
public import gtk.Expander;
public import gtk.FileChooserDialog;
public import gtk.FileFilter;
public import gtk.Fixed;
public import gtk.Frame;
public import gtk.HBox;
public import gtk.HRuler;
public import gtk.HSeparator;
public import gtk.IconFactory;
public import gtk.IconSet;
public import gtk.Image;
public import gtk.ImageMenuItem;
public import gtk.Label;
public import gtk.Layout;
public import gtk.ListStore;
public import gtk.Main;
public import gtk.MainWindow;
public import gtk.MenuItem;
public import gtk.MessageDialog;
public import gtk.Notebook;
public import gtk.ObjectGtk;
public import gtk.ScrolledWindow;
public import gtk.SpinButton;
public import gtk.StockItem;
public import gtk.Table;
public import gtk.Timeout;
public import gtk.ToggleButton;
public import gtk.ToolButton;
public import gtk.Toolbar;
public import gtk.ToolItem;
public import gtk.ToolItemGroup;
public import gtk.ToolPalette;
public import gtk.TreeIter;
public import gtk.TreeModel;
public import gtk.TreePath;
public import gtk.TreeStore;
public import gtk.TreeView;
public import gtk.TreeViewColumn;
public import gtk.VBox;
public import gtk.VRuler;
public import gtk.VSeparator;
public import gtk.Widget;
public import gtk.Window;

public import pango.PgCairo;
public import pango.PgLayout;
public import pango.PgFontDescription;

public import flexim.cpu.bpred;
public import flexim.cpu.instruction;
public import flexim.cpu.registers;

public import flexim.cpu.ooo.common;
public import flexim.cpu.ooo.pipelines;

public import flexim.io.logging;
public import flexim.io.xml;

public import flexim.isa.basic;
public import flexim.isa.branch;
public import flexim.isa.common;
public import flexim.isa.control;
public import flexim.isa.fp;
public import flexim.isa.integer;
public import flexim.isa.mem;
public import flexim.isa.misc;

public import flexim.ise.specifications;
public import flexim.ise.views;
public import flexim.ise.models;
public import flexim.ise.startup;

public import flexim.linux.process;
public import flexim.linux.syscall;

public import flexim.mem.functional.mem;
public import flexim.mem.functional.mmu;
public import flexim.mem.timing.cache;
public import flexim.mem.timing.common;
public import flexim.mem.timing.mem;
public import flexim.mem.timing.mesi;
public import flexim.mem.timing.sequencer;
public import flexim.mem.tm.transaction;

public import flexim.sim.benchmark;
public import flexim.sim.configs;
public import flexim.sim.simulations;
public import flexim.sim.simulator;
public import flexim.sim.stats;

public import flexim.util.arithmetic;
public import flexim.util.ds;
public import flexim.util.elf;
public import flexim.util.events;
public import flexim.util.faults;
public import flexim.util.mixins;

public import dstats.all;
public import plot2kill.all;
public import plot2kill.demotest;