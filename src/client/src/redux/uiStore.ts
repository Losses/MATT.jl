import *  as React from 'react';

import store, { HashTable } from './main';
import { UPDATE_INPUT } from './inputStore';
import FabricComponents from '../components/Fabric';

export type UIStatus = 'success' | 'error' | 'fetching' | 'not-ready' | 'updating';

interface NotReadyUIStore {
  status: 'not-ready';
}

interface FetchingUIStore {
  status: 'fetching';
}

interface ErrorUIStore {
  status: 'error';
  error: string;
}

interface SuccessUIStore {
  status: 'success' | 'updating';
  element: React.ReactElement<any>;
  input_bind: HashTable;
  bind_input: HashTable;
}

export type UIStore = NotReadyUIStore | FetchingUIStore | ErrorUIStore | SuccessUIStore;

export interface MATTAppDefinition {
  jsx_tree: JSXTreeDefinition;
  bind_input: HashTable;
  input_bind: HashTable;
}

export interface JSXTreeDefinition {
  hash: string;
  tag: string;
  component_type: 'input' | 'output' | 'static';
  props: { [hash: string]: any };
  children?: JSXTreeDefinition[];
}

export const START_FETCH_UI = 'start-fetch-ui';
export const REPORT_FETCH_UI_ERROR = 'report-fetch-ui-error';
export const UPDATE_UI = 'update-ui';
export const FINISH_UPDATE_UI = 'finish-update-ui';

interface StartFetchAction {
  type: 'start-fetch-ui';
}

interface ReportErrorAction {
  type: 'report-fetch-ui-error';
  error: string;
}

interface UpdateUIAction {
  type: 'update-ui';
  element: React.ReactElement<any>;
  input_bind: HashTable;
  bind_input: HashTable;
}

interface FinishUpdateUI {
  type: 'finish-update-ui';
}

export type UIAction = StartFetchAction | ReportErrorAction | UpdateUIAction | FinishUpdateUI;

const INITIAL_UI_STORE: UIStore = {
  status: 'not-ready'
}

export const uiReducer = (
  store: UIStore = INITIAL_UI_STORE,
  action: UIAction
): UIStore => {
  switch (action.type) {
    case START_FETCH_UI:
      return {
        status: 'fetching'
      }
    case REPORT_FETCH_UI_ERROR:
      return {
        status: 'error',
        error: action.error
      }
    case UPDATE_UI:
      return {
        status: 'updating',
        element: action.element,
        input_bind: action.input_bind,
        bind_input: action.bind_input
      }
    case FINISH_UPDATE_UI:
      return Object.assign(store, {
        status: 'success'
      })
    default:
      return store
  }
}

const parseJsxTreeDefinition = (x: JSXTreeDefinition): React.ReactElement => {
  let props;
  const children = x.children ? x.children.map(parseJsxTreeDefinition) : null;

  props = { ...x.props, __hash: x.hash };

  if (x.component_type == 'input') {
    const handleOnChange = (event: React.ChangeEvent<HTMLInputElement>) => {
      if (!event.target) return false
      store.dispatch({ type: UPDATE_INPUT, input: x.hash, value: event.target.value })
    }

    props = Object.assign(props, { onChange: handleOnChange });

    store.dispatch({ type: UPDATE_INPUT, input: x.hash, value: x.props.value })
  }

  return React.createElement(FabricComponents[x.tag], props, children);
}

export const getInitialUI = async () => {
  try {
    store.dispatch({ type: START_FETCH_UI });
    const ui_response = await fetch('/ui');
    const ui = await ui_response.json() as MATTAppDefinition;

    store.dispatch({
      type: UPDATE_UI,
      element: parseJsxTreeDefinition(ui.jsx_tree),
      input_bind: ui.input_bind,
      bind_input: ui.bind_input,
    });

    store.dispatch({ type: FINISH_UPDATE_UI });
  } catch (e) {
    store.dispatch({
      type: REPORT_FETCH_UI_ERROR,
      error: e.message
    })
  }
}