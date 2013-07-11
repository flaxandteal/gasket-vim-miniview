if exists("g:loaded_miniview")
	finish
endif
let g:loaded_miniview = 1

let s:save_cpo = &cpo
set cpo&vim

autocmd BufEnter * call <SID>Redisplay()
autocmd BufRead * call <SID>Redisplay()
autocmd CursorMoved * call <SID>Redisplay()
autocmd CursorMovedI * call <SID>Redisplay()

let s:current_file=expand("<sfile>")

python <<endpython
import vim, os
import lxml.etree as ET
import re

# Get Train up and running if it isn't already
plugin_folder = os.path.realpath(os.path.dirname(os.path.abspath(vim.eval("s:current_file"))) + "../../../trainconductor/plugin")
sys.path.insert(0, plugin_folder)
import trainconductor_vim

if vim.train is not None:
    miniview_car_id = vim.train.add_carriage("Miniview")
else:
    miniview_car_id = None

def generate_miniview():
    if miniview_car_id is None:
	return
    start = max(vim.current.range.start - 50, 0)
    end = min(len(vim.current.buffer), start + 100)
    lines = vim.current.buffer[start:end]
    search_term = vim.eval("@/")

    g = ET.Element('g')
    if len(lines) > 1:
        y = 1
        x = vim.current.window.width - 12
        height = .2
        longest_line = max(*map(len, vim.current.buffer))
        ratio = 10. / longest_line
        opacity = 0.3
        for linec in range(len(lines)):
            line = lines[linec]
            whitespace = (len(line) - len(line.lstrip())) * ratio
            width = (len(line)) * ratio
            y += height
            
            if vim.current.range.start <= start + linec and\
                   vim.current.range.end >= start + linec:
                line_colour = (0, 255, 0)
            else:
                line_colour = (255, 0, 0)
            found_colour = (255, 0, 255)
            #found_colour = tuple(map(lambda x:int(255-.25*(255-x)), line_colour))

            ET.SubElement(g, 'rect', x=str(x), y=str(y), width='1', height=str(height),
                **{'fill' : 'rgb(255, 255, 0)', 'fill-opacity' : str(opacity)})
            ET.SubElement(g, 'rect', x=str(x + 1), y=str(y), width=str(whitespace), height=str(height),
                **{'fill' : 'rgb' + str(line_colour) + '', 'fill-opacity' : str(opacity/5)})
            ET.SubElement(g, 'rect', x=str(x + 1 + whitespace), y=str(y), width=str(width-whitespace), height=str(height),
                **{'fill' : 'rgb' + str(line_colour) + '', 'fill-opacity' : str(opacity)})

            if search_term:
                try :
                    matches = re.finditer(search_term, line)
                except re.error :
                    pass
                else :
                    for match in matches:
                        offset = x + 1 + match.start() * ratio
                        width = (match.end() - match.start()) * ratio
                        ET.SubElement(g, 'rect', x=str(offset), y=str(y), width=str(width), height=str(height),
                                **{'fill' : 'rgb' + str(found_colour) + '', 'fill-opacity' : '1'})
    vim.train.update_carriage(miniview_car_id, g)
endpython

function! s:Redisplay()
	python <<endpython
generate_miniview()
endpython
endfunction

let &cpo = s:save_cpo
