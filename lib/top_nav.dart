import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'styled_button.dart';
import 'models/app_state.dart';
import 'models/state_manager_model.dart';

class TopNav extends StatelessWidget {
  const TopNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      color: Colors.blueAccent,
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StyledButton(Icons.home,null, 'Home'),
          StyledButton(Icons.assignment, null, 'Markdown'),
          StyledButton(Icons.zoom_in, null, 'Zoom', 
            (){
              context.read<StateManagerModel>().updateCurrentState(AppState.zooming);
            }
          ),
          StyledButton(Icons.brush, null, 'Paint', 
            (){
              context.read<StateManagerModel>().updateCurrentState(AppState.drawing);
            }
          ),
          StyledButton(Icons.add, null, 'New Block'),
          StyledButton(Icons.publish, null, 'Import',
            (){
                context.read<StateManagerModel>().updateCurrentState(AppState.importImage);
            }
          ),
          StyledButton(
              // 'assets/images/eraser-icon.svg',  // SVG asset path
              Icons.check_box_outline_blank,
              null,
              'Logo',                           // Label
              (){
                context.read<StateManagerModel>().updateCurrentState(AppState.erasing);
              }
            ),
          StyledButton(Icons.highlight_alt, null, 'Lasso',
          (){
            //if app state was already lasso, make app state to none 
            //final AppState lassoState = context.watch<StateManagerModel>().currentState == AppState.lassoing ? AppState.none: AppState.lassoing;
            
            final AppState currentState = Provider.of<StateManagerModel>(context, listen: false).currentState;
            final AppState lassoState = currentState == AppState.lassoing ? AppState.none : AppState.lassoing;
            //Provider.of<StateManagerModel>(context, listen: false).updateCurrentState(lassoState);
            context.read<StateManagerModel>().updateCurrentState(lassoState);
          }),
          StyledButton(Icons.open_in_full, null, 'Resize', (){
            context.read<StateManagerModel>().updateCurrentState(AppState.resizingBlock);
          }),
        ],
      ),
    );
  }
}