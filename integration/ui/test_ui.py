#!/usr/bin/env python3
"""Offline layout/raster invariants using pinned metrics, never a runtime claim."""
import json,re,unittest,tempfile
from pathlib import Path
from preview import Renderer,ROOT,CAT,L
import sys
sys.path.insert(0,str(ROOT))
from generate_font import generate
from PIL import Image
class UiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.renderers=[Renderer(i) for i in range(2)]
    def test_font_reproducible(self):
        first,count=generate();second,_=generate();self.assertEqual(first,second)
        for name,data in first.items():self.assertEqual(data,(ROOT/'assets'/name).read_bytes())
        self.assertGreater(count,300)
    def test_font_binary_pixels(self):
        image=Image.open(ROOT/'assets/ui-font.png').convert('RGBA')
        self.assertEqual(set(image.getchannel('A').tobytes()),{0,255})
        pixels=image.tobytes()
        for red,green,blue,alpha in zip(pixels[0::4],pixels[1::4],pixels[2::4],pixels[3::4]):
            if alpha:self.assertEqual((red,green,blue),(255,255,255))
    def test_all_warning_states_fit(self):
        for language,r in enumerate(self.renderers):
            for code in range(1,21):
                text='* '+r.text('warn_'+str(code));lines=r.wrap(text,L['warning_width'],L['warning_lines'])
                self.assertTrue(lines);self.assertFalse(lines[-1].endswith('...'),(language,code,lines))
                for enforced in [False,True]:
                    r.runs=[];r.warning(code,enforced)
                    for x,y,w,h,text in r.runs:
                        self.assertGreaterEqual(x,L['warning_left']+3);self.assertGreaterEqual(y,L['warning_top']+3)
                        self.assertLessEqual(x+w,L['warning_right']-3);self.assertLessEqual(y+h,L['warning_bottom']-3)
    def test_menu_cursor_and_rows_fit(self):
        for r in self.renderers:
            for selected in range(7):
                r.runs=[];r.menu(selected)
                for x,y,w,h,text in r.runs:
                    self.assertLessEqual(x+w,L['menu_right']-3);self.assertLessEqual(y+h,L['menu_bottom']-3)
            for size in [2,3,4,5,19]:
                for selected in range(size):
                    options=[('Variant ' if r.lang==0 else '변형 ')+str(i) for i in range(size)]
                    r.runs=[];r.menu(selected,options)
                    self.assertLessEqual(len(r.runs),L['visible_rows']+2)
                    first=selected//L['visible_rows']*L['visible_rows'];self.assertIn(options[selected],[run[4] for run in r.runs])
    def test_hud_clip_and_coverage(self):
        for r in self.renderers:
            for message in ['Long objective '*50,'남은 필수 조우를 마치세요. '*50]:
                r.runs=[];r.hud(message)
                for x,y,w,h,text in r.runs:
                    self.assertLessEqual(x+w,301);self.assertLessEqual(y+h,L['hud_bottom']-3)
        self.assertLessEqual((L['hud_bottom']-L['hud_top'])/240,0.12)
    def test_labels_do_not_hide_distinctions(self):
        source=(ROOT/'gml/neutral_label.gml').read_text()
        for literal in re.findall(r'return ("[^"\n]*")',source):
            text=json.loads(literal);language=int(any(ord(c)>126 for c in text));r=self.renderers[language]
            self.assertLessEqual(r.width(text),252,text)
    def test_full_objectives_fit_progress_page(self):
        for path in [ROOT/'gml/route_objective.gml',ROOT/'gml/neutral_evaluate.gml',ROOT/'gml/greeting_evaluate.gml']:
            for literal in re.findall(r'"(?:[^"\\]|\\.)*"',path.read_text()):
                text=json.loads(literal)
                if len(text)<30:continue
                language=int(any(ord(c)>126 for c in text));r=self.renderers[language]
                self.assertFalse(r.wrap('* '+text,264,4)[-1].endswith('...'),text)
    def test_progress_counter_is_not_truncated(self):
        for r in self.renderers:
            for total in range(1,100):
                text=f'{total}/{total}'
                self.assertEqual(r.fit(text,L['hud_progress_width']),text)
    def test_geometry_matches_original_dialogue(self):
        self.assertEqual(L['border'],3);self.assertEqual(L['warning_left'],16);self.assertEqual(L['warning_right'],304)
        self.assertEqual(L['scale'],2)
    def test_native_source_safety_contract(self):
        draw=(ROOT/'gml/controller_draw.gml').read_text();step=(ROOT/'gml/controller_step.gml').read_text()
        self.assertIn('draw_set_font(fnt_maintext)',draw);self.assertNotIn('display_set_gui_size',draw)
        self.assertNotIn('gameplay tests pending',draw);self.assertIn('control_check_pressed(0)',step);self.assertIn('control_check_pressed(1)',step)
        self.assertGreater(step.index('control_clear(0); control_clear(1); control_clear(2);',step.index('accept = control_check_pressed(0)')),step.index('cancel = control_check_pressed(1)'))
        self.assertIn('obj_routekeeper.rk_menu',(ROOT/'hooks.csx').read_text())
        self.assertIn('string_pos("한국어",argument2)',(ROOT/'gml/ui_line.gml').read_text())
    def test_small_controller_and_disconnect_contract(self):
        step=(ROOT/'gml/controller_step.gml').read_text()
        self.assertIn('rk_pad_ready = count > 0;',step)
        self.assertIn('if (rk_pad_ready && j < count)',step)
        self.assertIn('rk_pad_button[j] = -1;',step)
        self.assertIn('pad_signature == rk_pad_signature',step)
    def test_clipping_empty_and_exact_width(self):
        for r in self.renderers:
            self.assertEqual(r.fit('',10),'');self.assertEqual(r.fit('abc',r.width('abc')),'abc')
            self.assertTrue(r.fit('long text',20).endswith('...'))
    def test_preview_bytes_are_reproducible_and_pixels_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            for r in self.renderers:
                r.menu(2);a=Path(directory)/'a.png';b=Path(directory)/'b.png'
                r.save(a);r.save(b);self.assertEqual(a.read_bytes(),b.read_bytes())
                expected=r.image.resize((640,480),Image.Resampling.NEAREST).tobytes()
                self.assertEqual(Image.open(a).convert('RGBA').tobytes(),expected)
    def test_neutral_settings_and_call_goal_pages(self):
        for r in self.renderers:
            goals=r.call_goals();self.assertEqual(len(goals),9)
            self.assertEqual(len(set(goals)),9)
            for goal in range(9):
                self.assertLessEqual(r.width(goals[goal]),252)
                r.runs=[];r.menu(goal,goals)
                self.assertIn(goals[goal],[run[4] for run in r.runs])
                for x,y,w,h,text in r.runs:
                    self.assertLessEqual(x+w,301);self.assertLessEqual(y+h,L['menu_bottom']-3)
                for selected in range(3):
                    r.runs=[];r.menu(selected,neutral=True,neutral_settings=True,goal=goal)
                    for x,y,w,h,text in r.runs:
                        self.assertLessEqual(x+w,301);self.assertLessEqual(y+h,L['menu_bottom']-3)
            r.runs=[];r.menu(1,neutral=True)
            self.assertNotIn('All',[run[4] for run in r.runs])
            self.assertNotIn('Variant',[run[4] for run in r.runs])
    def test_readiness_and_input_event_order_contract(self):
        state=(ROOT/'gml/state_read.gml').read_text();step=(ROOT/'gml/controller_step.gml').read_text()
        self.assertLess(state.index('return 0;'),state.index('global.flag['))
        self.assertIn('if (global.rk_state_ready && instance_exists(obj_mainchara)',step)
        self.assertLess(step.index('rk_menu_fence = rk_menu;'),step.index('scr_routekeeper_read_state();'))
        self.assertLess(step.index('rk_direction_up = held_up;'),step.index('if (global.rk_warning_pending) {',step.index('rk_direction_up = held_up;')))
        self.assertIn('obj_routekeeper.rk_menu_fence',(ROOT/'hooks.csx').read_text())
        self.assertIn('!global.rk_state_ready || global.rk_warning_room != room',step)
    def test_pre_effect_save_item_and_lab_hooks(self):
        hooks=(ROOT/'hooks.csx').read_text();guard=(ROOT/'gml/decision_guard.gml').read_text()
        for action in [8,9,10]:self.assertIn('scr_routekeeper_decision_guard('+str(action)+',',hooks)
        self.assertIn('room == room_fire_lab1',guard)
        self.assertIn('scr_routekeeper_warning_session(1, risk, context, enforceable)',guard)
        self.assertIn('string(global.rk_mode)',guard)
        self.assertLess(guard.index('!global.rk_state_ready'),guard.index('global.flag[26]'))
    def test_unproven_compound_forced_combination_fails_safely(self):
        guard=(ROOT/'gml/decision_guard.gml').read_text()
        self.assertIn('scr_routekeeper_decision_enforceable(risk, action, family',guard)
        scope=(ROOT/'gml/decision_enforceable.gml').read_text()
        self.assertIn('argument0 == 17',scope);self.assertIn('argument4 == 8',scope)
        self.assertIn('return 0;',scope)
        create=(ROOT/'gml/controller_create.gml').read_text();step=(ROOT/'gml/controller_step.gml').read_text()
        self.assertIn('global.rk_warning_pending = 0;',create);self.assertIn('global.rk_warning_ack = 0;',create)
        self.assertNotIn('ini_write_real("Guidance", "warning',step)
    def test_reload_and_pre_effect_refresh(self):
        hooks=(ROOT/'hooks.csx').read_text();guard=(ROOT/'gml/decision_guard.gml').read_text()
        self.assertIn('["gml_Script_scr_load"]',hooks)
        self.assertIn('global.rk_history_refresh = 0;',hooks)
        self.assertIn('obj_routekeeper.rk_menu_fence = 0;',hooks)
        self.assertLess(guard.index('scr_routekeeper_read_state();'),guard.index('obj_routekeeper.rk_status == 3'))
        pending=(ROOT/'gml/greeting_pending_risk.gml').read_text()
        self.assertEqual(pending.count('global.xpreward[3]'),2)
    def test_baseline_cell_bounds(self):
        rows=[list(map(int,row.split())) for row in (ROOT/'assets/ui-font.tsv').read_text().splitlines()]
        im=Image.open(ROOT/'assets/ui-font.png').convert('RGBA')
        for code,x,y,advance,offset in rows:
            self.assertIsNone(im.crop((x,y+18,x+24,y+24)).getbbox(),f'Ink clipped below U+{code:04X}')
            self.assertTrue(0<=advance<=24)
if __name__=='__main__':unittest.main(verbosity=2)
