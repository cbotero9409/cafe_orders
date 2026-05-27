module ProductsHelper
  TAB_BASE = "px-4 py-2 rounded-lg text-sm font-medium transition-colors duration-150 cursor-pointer"

  def tab_active_classes
    "#{TAB_BASE} bg-amber-800 text-white shadow-sm"
  end

  def tab_inactive_classes
    "#{TAB_BASE} text-stone-600 hover:bg-stone-200"
  end

  def filter_tab_class(current, tab)
    current == tab ? tab_active_classes : tab_inactive_classes
  end

  def filter_tabs
    [
      [ "Available", "available" ],
      [ "Active",    "active"    ],
      [ "All",       "all"       ]
    ]
  end
end
