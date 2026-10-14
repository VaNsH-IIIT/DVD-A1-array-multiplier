# KLayout batch script: render the final GDS to PNG (whole die + zoomed view).
# Run from the repository root inside the container:
#   klayout -zz -r report/figures/render_layout.py \
#       -rd gds=pnr/mult_array.gds -rd lyp=$PDK_ROOT/sky130A/libs.tech/klayout/tech/sky130A.lyp \
#       -rd out=report/figures/partD_layout -rd zx_=50 -rd zy_=74 -rd zw=34
import pya

lv = pya.LayoutView()
lv.set_config("background-color", "#ffffff")
lv.set_config("grid-visible", "false")
lv.set_config("text-visible", "false")
idx = lv.load_layout(gds, True)
if lyp:
    lv.load_layer_props(lyp)
lv.max_hier()
top = lv.cellview(idx).layout().top_cell()
bb = top.dbbox()
print("top cell:", top.name, "bbox (um):", bb)

# whole die
lv.zoom_box(bb.enlarged(2, 2))
lv.save_image(out + "_die.png", 1800, 1800)

# zoomed view centred on (zx_, zy_) um, zw um wide
w = float(zw)
h = w * 0.72
zx, zy = float(zx_), float(zy_)
lv.zoom_box(pya.DBox(zx - w / 2, zy - h / 2, zx + w / 2, zy + h / 2))
lv.save_image(out + "_zoom.png", 1800, 1300)
print("wrote", out + "_die.png", out + "_zoom.png")
