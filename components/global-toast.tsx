'use client';
import {useEffect,useState} from 'react';
import {CheckCircle2} from 'lucide-react';
export function GlobalToast(){const [message,setMessage]=useState('');useEffect(()=>{const handler=(event:Event)=>{const custom=event as CustomEvent<string>;setMessage(custom.detail);window.setTimeout(()=>setMessage(''),2600)};window.addEventListener('panda-toast',handler);return()=>window.removeEventListener('panda-toast',handler)},[]);return message?<div role="status" className="fixed right-4 top-20 z-[60] flex items-center gap-2 rounded-xl bg-gray-900 px-4 py-3 text-sm font-semibold text-white shadow-xl"><CheckCircle2 size={18} className="text-emerald-300"/>{message}</div>:null}
