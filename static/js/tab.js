layui.define(['element', 'common'], function(exports) {
	"use strict";

	var mod_name = 'tab',
		$ = layui.jquery,
		element = layui.element(),
		commom = layui.common,
		globalTabIdIndex = 0,
		Tab = function() {
			this.config = {
				elem: undefined,
				closed: true, //是否包含删除按钮				
				autoRefresh: false
			};
		};
	var ELEM = {};
	/**
	 * 参数设置
	 * @param {Object} options
	 */
	Tab.prototype.set = function(options) {
		var that = this;
		$.extend(true, that.config, options);
		return that;
	};
	/**
	 * 初始化
	 */
	Tab.prototype.init = function() {
		var that = this;
		var _config = that.config;
		if(typeof(_config.elem) !== 'string' && typeof(_config.elem) !== 'object') {
			common.throwError('Tab error: elem参数未定义或设置出错，具体设置格式请参考文档API.');
		}
		var $container;
		if(typeof(_config.elem) === 'string') {
			$container = $('' + _config.elem + '');
		}
		if(typeof(_config.elem) === 'object') {
			$container = _config.elem;
		}
		if($container.length === 0) {
			common.throwError('Tab error:找不到elem参数配置的容器，请检查.');
		}
		var filter = $container.attr('lay-filter');
		if(filter === undefined || filter === '') {
			common.throwError('Tab error:请为elem容器设置一个lay-filter过滤器');
		}
		_config.elem = $container;
		ELEM.titleBox = $container.children('ul.layui-tab-title');
		ELEM.contentBox = $container.children('div.layui-tab-content');
		ELEM.tabFilter = filter;
		return that;
	};
	/**
	 * 查询tab是否存在，如果存在则返回索引值，不存在返回-1
	 * @param {String} 标题
	 */
	Tab.prototype.exists = function(title) {
		var that = ELEM.titleBox === undefined ? this.init() : this,
			tabIndex = -1;
		ELEM.titleBox.find('li').each(function(i, e) {
			var $cite = $(this).children('cite');
			if($cite.text() === title) {
				tabIndex = i;
			};
		});
		return tabIndex;
	};
	/**
	 * 添加选择卡，如果选择卡存在则获取焦点
	 * @param {Object} data
	 */
	Tab.prototype.tabAdd = function(data) {
		var that = this;
		var _config = that.config;
		var tabIndex = that.exists(data.title);
		if(tabIndex === -1) {
			globalTabIdIndex++;
			var content = '<iframe src="' + data.href + '" data-id="' + globalTabIdIndex + '"></iframe>';
			var title = '';
			if(data.icon !== undefined) {
				if(data.icon.indexOf('fa-') !== -1) {
					title += '<i class="fa ' + data.icon + '" aria-hidden="true"></i>';
				} else {
					title += '<i class="layui-icon">' + data.icon + '</i>';
				}
			}
			title += '<cite>' + data.title + '</cite>';
			if(_config.closed) {
				title += '<i class="layui-icon layui-unselect layui-tab-close" data-id="' + globalTabIdIndex + '">&#x1006;</i>';
			}
			//添加tab
			element.tabAdd(ELEM.tabFilter, {
				title: title,
				content: content
			});
			//iframe 自适应
			ELEM.contentBox.find('iframe[data-id=' + globalTabIdIndex + ']').each(function() {
				$(this).height(ELEM.contentBox.height());
			});
			if(_config.closed) {
				//监听关闭事件
				ELEM.titleBox.find('li').children('i.layui-tab-close[data-id=' + globalTabIdIndex + ']').on('click', function() {
					element.tabDelete(ELEM.tabFilter, $(this).parent('li').index()).init();
				});
			};
			//切换到当前打开的选项卡
			element.tabChange(ELEM.tabFilter, ELEM.titleBox.find('li').length - 1);
		} else {
			element.tabChange(ELEM.tabFilter, tabIndex);
			//自动刷新
			if(_config.autoRefresh) {
				_config.elem.find('div.layui-tab-content > div').eq(tabIndex).children('iframe')[0].contentWindow.location.reload();
			}
		}
	};
	Tab.prototype.on = function(events, callback) {

	}

	var tab = new Tab();
	exports(mod_name, function(options) {
		return tab.set(options);
	});
});