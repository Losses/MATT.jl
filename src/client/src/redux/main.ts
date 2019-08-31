import { createStore, combineReducers } from 'redux';
import { uiReducer, UIStore } from './uiStore';
import { inputReducer, InputStore } from './inputStore';
import { outputReducer, OutputStore } from './outputStore';
import { connectionReducer, ConnectionStore } from './connectonStore';

export type HashTable = { [hash: string]: string[] };

export interface MATTStore {
  ui: UIStore;
  inputs: InputStore;
  outputs: OutputStore;
  connection: ConnectionStore;
};

const rootReducer = combineReducers({
  ui: uiReducer,
  inputs: inputReducer, 
  outputs: outputReducer,
  connection: connectionReducer
})

export default createStore(rootReducer);