# CheatsheetMail - Progresso de Implementação

Status do Design (Tailwind gerado via Figma):

```html
<!-- [x] Container Principal (Navigation Sidebar) -->
<div class="self-stretch self-stretch p-3 bg-neutral-800 rounded-tl-[48px] rounded-tr rounded-bl-[48px] rounded-br inline-flex flex-col justify-between items-center">
    
    <div class="w-72 flex flex-col justify-start items-start gap-12">
        <!-- [x] Compose Button -->
        <div class="self-stretch px-6 py-4 bg-zinc-500 rounded-[72px] inline-flex justify-center items-center gap-3 overflow-hidden">
            <div class="w-8 h-8 bg-stone-950"></div>
            <div class="w-28 text-center justify-start text-stone-950 text-2xl font-bold font-['Google_Sans_Flex'] leading-10">Compose</div>
        </div>
        
        <!-- [x] Menu Items Container -->
        <div class="self-stretch flex flex-col justify-start items-start gap-1">
            <!-- [x] Inbox -->
            <div class="self-stretch px-9 py-2 bg-rose-700 rounded-[36px] inline-flex justify-start items-center gap-6 overflow-hidden">
                <div class="w-6 h-6 bg-white"></div>
                <div class="text-center justify-start text-white text-2xl font-semibold font-['Google_Sans_Flex'] leading-10">Inbox</div>
            </div>
            
            <!-- [x] Spam -->
            <div class="self-stretch px-9 py-2 bg-neutral-700 rounded inline-flex justify-start items-center gap-6 overflow-hidden">
                <div class="w-6 h-6 bg-stone-300"></div>
                <div class="text-center justify-start text-stone-300 text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Spam</div>
            </div>
            
            <!-- [x] Sent -->
            <div class="self-stretch px-9 py-2 bg-neutral-700 rounded-tl rounded-tr rounded-bl-[36px] rounded-br-[36px] inline-flex justify-start items-center gap-6 overflow-hidden">
                <div class="w-7 h-6 bg-stone-300"></div>
                <div class="text-center justify-start text-stone-300 text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Sent</div>
            </div>
        </div>
    </div>
    
    <!-- [ ] Search & Settings Container -->
    <div class="w-72 flex flex-col justify-start items-start gap-3">
        <!-- [ ] Search -->
        <div class="self-stretch px-9 py-2 bg-zinc-800 rounded-[36px] outline outline-1 outline-stone-500 inline-flex justify-start items-center gap-6 overflow-hidden">
            <div class="w-7 h-7 bg-stone-200"></div>
            <div class="text-center justify-start text-stone-200 text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Search</div>
        </div>
        
        <!-- [ ] Settings -->
        <div class="self-stretch px-9 py-2 bg-zinc-800 rounded-[36px] inline-flex justify-start items-center gap-6 overflow-hidden">
            <div class="w-7 h-7 bg-stone-200"></div>
            <div class="text-center justify-start text-stone-200 text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Settings</div>
        </div>
    </div>
</div>
```

<!-- EMAIL CARD-->
<div class="self-stretch h-24 rounded-3xl inline-flex justify-start items-start gap-1">
    <div class="w-60 self-stretch p-3 bg-zinc-800 rounded-tl-[48px] rounded-tr rounded-bl rounded-br flex justify-start items-center gap-2.5 overflow-hidden">
        <div class="w-20 self-stretch p-4 bg-neutral-800 rounded-full flex justify-center items-center overflow-hidden">
            <div class="w-7 self-stretch bg-zinc-500"></div>
        </div>
        <div class="flex-1 justify-center text-stone-200 text-base font-bold font-['Google_Sans_Flex'] leading-6 tracking-wide line-clamp-1">User Feedback</div>
    </div>
    <div class="flex-1 self-stretch px-6 py-3 bg-zinc-800 rounded-tl rounded-tr-[48px] rounded-bl rounded-br inline-flex flex-col justify-center items-start gap-1">
        <div class="justify-center text-stone-200 text-base font-semibold font-['Google_Sans_Flex'] leading-6 tracking-wide">Monthly Customer Satisfaction Survey</div>
        <div class="self-stretch justify-center text-stone-400 text-sm font-medium font-['Google_Sans_Flex'] leading-6 tracking-wide line-clamp-1">We value your feedback! Please take a moment to share your thoughts on our latest features and improvements.</div>
    </div>
</div>


<!-- SETTINGS PAGE -->
<div class="w-[1026px] p-6 bg-neutral-800 rounded-tl rounded-tr-[48px] rounded-bl rounded-br-3xl inline-flex flex-col justify-start items-start gap-12 overflow-hidden">
    <div class="self-stretch flex flex-col justify-start items-end gap-6">
        <div class="self-stretch px-6 py-3 bg-neutral-700 rounded-3xl inline-flex justify-start items-start gap-6">
            <div class="w-20 self-stretch relative">
                <div class="w-20 h-20 left-0 top-0 absolute bg-pink-950"></div>
                <div class="w-8 h-4 left-[25.88px] top-[33.52px] absolute bg-stone-200"></div>
            </div>
            <div class="inline-flex flex-col justify-start items-start gap-1">
                <div class="text-center justify-start text-white text-3xl font-medium font-['Google_Sans_Flex'] leading-10">Connected account:</div>
                <div class="text-center justify-start text-stone-400 text-2xl font-normal font-['Google_Sans_Flex'] leading-10">email@gmail.com</div>
            </div>
        </div>
        <div class="px-9 py-5 bg-rose-700 rounded-[72px] inline-flex justify-start items-center gap-6 overflow-hidden">
            <div class="text-center justify-start text-stone-200 text-2xl font-bold font-['Google_Sans_Flex'] leading-10">Disconnect account</div>
        </div>
    </div>
    <div class="self-stretch flex flex-col justify-start items-start gap-3">
        <div class="self-stretch inline-flex justify-start items-start gap-3">
            <div class="flex-1 px-6 py-3 bg-neutral-700 rounded-3xl flex justify-start items-start gap-6">
                <div class="w-10 self-stretch relative">
                    <div class="w-10 h-10 left-0 top-0 absolute bg-pink-950"></div>
                    <div class="w-4 h-2 left-[12.32px] top-[15.96px] absolute bg-stone-200"></div>
                </div>
                <div class="inline-flex flex-col justify-start items-start gap-1">
                    <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Number of emails to load:</div>
                </div>
            </div>
            <div class="flex justify-start items-center gap-1">
                <div class="w-16 h-16 px-6 py-3 bg-neutral-700 rounded-tl-3xl rounded-tr rounded-bl-3xl rounded-br flex justify-center items-center gap-6">
                    <div class="inline-flex flex-col justify-start items-start gap-1">
                        <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">-</div>
                    </div>
                </div>
                <div class="w-16 h-16 px-6 py-3 bg-neutral-700 rounded flex justify-center items-center gap-6">
                    <div class="inline-flex flex-col justify-start items-start gap-1">
                        <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">50</div>
                    </div>
                </div>
                <div class="w-16 h-16 px-6 py-3 bg-neutral-700 rounded-tl rounded-tr-3xl rounded-bl rounded-br-3xl flex justify-center items-center gap-6">
                    <div class="inline-flex flex-col justify-start items-start gap-1">
                        <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">+</div>
                    </div>
                </div>
            </div>
        </div>
        <div class="self-stretch inline-flex justify-start items-start gap-3">
            <div class="flex-1 px-6 py-3 bg-neutral-700 rounded-3xl flex justify-start items-start gap-6">
                <div class="w-10 self-stretch relative">
                    <div class="w-10 h-10 left-0 top-0 absolute bg-pink-950"></div>
                    <div class="w-4 h-2 left-[12.32px] top-[15.96px] absolute bg-stone-200"></div>
                </div>
                <div class="inline-flex flex-col justify-start items-start gap-1">
                    <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Refresh interval (minutes)</div>
                </div>
            </div>
            <div class="flex justify-start items-center gap-1">
                <div class="w-16 h-16 px-6 py-3 bg-neutral-700 rounded-tl-3xl rounded-tr rounded-bl-3xl rounded-br flex justify-center items-center gap-6">
                    <div class="inline-flex flex-col justify-start items-start gap-1">
                        <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">-</div>
                    </div>
                </div>
                <div class="w-16 h-16 px-6 py-3 bg-neutral-700 rounded flex justify-center items-center gap-6">
                    <div class="inline-flex flex-col justify-start items-start gap-1">
                        <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">50</div>
                    </div>
                </div>
                <div class="w-16 h-16 px-6 py-3 bg-neutral-700 rounded-tl rounded-tr-3xl rounded-bl rounded-br-3xl flex justify-center items-center gap-6">
                    <div class="inline-flex flex-col justify-start items-start gap-1">
                        <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">+</div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="self-stretch flex flex-col justify-start items-start gap-1">
        <div class="text-center justify-start text-stone-300 text-xl font-normal font-['Google_Sans_Flex'] leading-10">Categories</div>
        <div class="self-stretch flex flex-col justify-start items-start gap-1">
            <div class="self-stretch px-6 py-3 bg-neutral-700 rounded-tl-3xl rounded-tr-3xl rounded-bl rounded-br inline-flex justify-between items-center">
                <div class="flex justify-center items-center gap-6">
                    <div class="w-10 self-stretch relative">
                        <div class="w-10 h-10 left-0 top-0 absolute bg-pink-950"></div>
                        <div class="w-4 h-2 left-[12.32px] top-[15.96px] absolute bg-stone-200"></div>
                    </div>
                    <div class="inline-flex flex-col justify-start items-start gap-1">
                        <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Enable Updates</div>
                    </div>
                </div>
                <div class="w-12 h-8 px-1 py-0.5 bg-rose-700 rounded-[100px] flex justify-end items-center">
                    <div class="flex-1 self-stretch relative">
                        <div class="p-1 left-[8px] top-[-10px] absolute inline-flex justify-center items-center">
                            <div class="p-2 rounded-[100px] inline-flex flex-col justify-center items-center gap-2">
                                <div class="p-2.5 relative bg-Schemes-On-Primary rounded-3xl inline-flex justify-center items-center overflow-hidden">
                                    <div class="w-0.5 h-0.5 rounded-3xl"></div>
                                    <div class="w-4 h-4 left-[4px] top-[4px] absolute overflow-hidden">
                                        <div class="w-2.5 h-2 left-[2.57px] top-[3.98px] absolute bg-rose-700"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <!-- Refinamentos de UI e Polish -->
            <div class="self-stretch px-6 py-3 bg-neutral-800 rounded-lg shadow-md border border-neutral-600 my-2">
                <h4 class="text-rose-500 font-bold mb-2">[MODIFY] EmailAuth.qml:</h4>
                <ul class="text-stone-300 text-sm list-disc pl-5">
                    <li>Nova tela de <b>Tutorial de Setup</b> exibida automaticamente se o <code>.env</code> estiver vazio.</li>
                    <li>Guia passo a passo refinado com instruções de <b>Scopes da API</b> (modify, send, email, profile).</li>
                    <li>Números dos passos centralizados perfeitamente.</li>
                    <li>Botão "Check Credentials" agora possui feedback visual de carregamento (spinner).</li>
                    <li>Botão "Open .env" reforçado com fallbacks para diversos editores de texto.</li>
                    <li>Container de snippet de código agora possui bordas arredondadas corretas.</li>
                </ul>
            </div>
            <div class="self-stretch px-6 py-3 bg-neutral-700 rounded inline-flex justify-between items-center">
                <div class="flex justify-center items-center gap-6">
                    <div class="w-10 self-stretch relative">
                        <div class="w-10 h-10 left-0 top-0 absolute bg-pink-950"></div>
                        <div class="w-4 h-2 left-[12.32px] top-[15.96px] absolute bg-stone-200"></div>
                    </div>
                    <div class="inline-flex flex-col justify-start items-start gap-1">
                        <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Enable Promotions</div>
                    </div>
                </div>
                <div class="w-12 h-8 px-1 py-0.5 bg-rose-700 rounded-[100px] flex justify-end items-center">
                    <div class="flex-1 self-stretch relative">
                        <div class="p-1 left-[8px] top-[-10px] absolute inline-flex justify-center items-center">
                            <div class="p-2 rounded-[100px] inline-flex flex-col justify-center items-center gap-2">
                                <div class="p-2.5 relative bg-Schemes-On-Primary rounded-3xl inline-flex justify-center items-center overflow-hidden">
                                    <div class="w-0.5 h-0.5 rounded-3xl"></div>
                                    <div class="w-4 h-4 left-[4px] top-[4px] absolute overflow-hidden">
                                        <div class="w-2.5 h-2 left-[2.57px] top-[3.98px] absolute bg-rose-700"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="self-stretch px-6 py-3 bg-neutral-700 rounded-tl rounded-tr rounded-bl-3xl rounded-br-3xl inline-flex justify-between items-center">
                <div class="flex justify-center items-center gap-6">
                    <div class="w-10 self-stretch relative">
                        <div class="w-10 h-10 left-0 top-0 absolute bg-pink-950"></div>
                        <div class="w-4 h-2 left-[12.32px] top-[15.96px] absolute bg-stone-200"></div>
                    </div>
                    <div class="inline-flex flex-col justify-start items-start gap-1">
                        <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Enable Social</div>
                    </div>
                </div>
                <div class="w-12 h-8 px-1 py-0.5 bg-rose-700 rounded-[100px] flex justify-end items-center">
                    <div class="flex-1 self-stretch relative">
                        <div class="p-1 left-[8px] top-[-10px] absolute inline-flex justify-center items-center">
                            <div class="p-2 rounded-[100px] inline-flex flex-col justify-center items-center gap-2">
                                <div class="p-2.5 relative bg-Schemes-On-Primary rounded-3xl inline-flex justify-center items-center overflow-hidden">
                                    <div class="w-0.5 h-0.5 rounded-3xl"></div>
                                    <div class="w-4 h-4 left-[4px] top-[4px] absolute overflow-hidden">
                                        <div class="w-2.5 h-2 left-[2.57px] top-[3.98px] absolute bg-rose-700"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="self-stretch flex flex-col justify-start items-start gap-1">
        <div class="text-center justify-start text-stone-300 text-xl font-normal font-['Google_Sans_Flex'] leading-10">Custom Tags</div>
        <div class="self-stretch px-6 py-3 bg-neutral-700 rounded-tl-3xl rounded-tr-3xl rounded-bl rounded-br inline-flex justify-between items-center">
            <div class="flex justify-center items-center gap-6">
                <div class="w-10 self-stretch relative">
                    <div class="w-10 h-10 left-0 top-0 absolute bg-pink-950"></div>
                    <div class="w-4 h-2 left-[12.32px] top-[15.96px] absolute bg-stone-200"></div>
                </div>
                <div class="inline-flex flex-col justify-start items-start gap-1">
                    <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Banco</div>
                </div>
            </div>
            <div class="w-12 h-8 px-1 py-0.5 bg-rose-700 rounded-[100px] flex justify-end items-center">
                <div class="flex-1 self-stretch relative">
                    <div class="p-1 left-[8px] top-[-10px] absolute inline-flex justify-center items-center">
                        <div class="p-2 rounded-[100px] inline-flex flex-col justify-center items-center gap-2">
                            <div class="p-2.5 relative bg-Schemes-On-Primary rounded-3xl inline-flex justify-center items-center overflow-hidden">
                                <div class="w-0.5 h-0.5 rounded-3xl"></div>
                                <div class="w-4 h-4 left-[4px] top-[4px] absolute overflow-hidden">
                                    <div class="w-2.5 h-2 left-[2.57px] top-[3.98px] absolute bg-rose-700"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="self-stretch px-6 py-3 bg-neutral-700 rounded inline-flex justify-between items-center">
            <div class="flex justify-center items-center gap-6">
                <div class="w-10 self-stretch relative">
                    <div class="w-10 h-10 left-0 top-0 absolute bg-pink-950"></div>
                    <div class="w-4 h-2 left-[12.32px] top-[15.96px] absolute bg-stone-200"></div>
                </div>
                <div class="inline-flex flex-col justify-start items-start gap-1">
                    <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Banco</div>
                </div>
            </div>
            <div class="w-12 h-8 px-1 py-0.5 bg-rose-700 rounded-[100px] flex justify-end items-center">
                <div class="flex-1 self-stretch relative">
                    <div class="p-1 left-[8px] top-[-10px] absolute inline-flex justify-center items-center">
                        <div class="p-2 rounded-[100px] inline-flex flex-col justify-center items-center gap-2">
                            <div class="p-2.5 relative bg-Schemes-On-Primary rounded-3xl inline-flex justify-center items-center overflow-hidden">
                                <div class="w-0.5 h-0.5 rounded-3xl"></div>
                                <div class="w-4 h-4 left-[4px] top-[4px] absolute overflow-hidden">
                                    <div class="w-2.5 h-2 left-[2.57px] top-[3.98px] absolute bg-rose-700"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="self-stretch px-6 py-3 bg-neutral-700 rounded-tl rounded-tr rounded-bl-3xl rounded-br-3xl inline-flex justify-between items-center">
            <div class="flex justify-center items-center gap-6">
                <div class="w-10 self-stretch relative">
                    <div class="w-10 h-10 left-0 top-0 absolute bg-pink-950"></div>
                    <div class="w-4 h-2 left-[12.32px] top-[15.96px] absolute bg-stone-200"></div>
                </div>
                <div class="inline-flex flex-col justify-start items-start gap-1">
                    <div class="text-center justify-start text-white text-2xl font-normal font-['Google_Sans_Flex'] leading-10">Banco</div>
                </div>
            </div>
            <div class="w-12 h-8 px-1 py-0.5 bg-rose-700 rounded-[100px] flex justify-end items-center">
                <div class="flex-1 self-stretch relative">
                    <div class="p-1 left-[8px] top-[-10px] absolute inline-flex justify-center items-center">
                        <div class="p-2 rounded-[100px] inline-flex flex-col justify-center items-center gap-2">
                            <div class="p-2.5 relative bg-Schemes-On-Primary rounded-3xl inline-flex justify-center items-center overflow-hidden">
                                <div class="w-0.5 h-0.5 rounded-3xl"></div>
                                <div class="w-4 h-4 left-[4px] top-[4px] absolute overflow-hidden">
                                    <div class="w-2.5 h-2 left-[2.57px] top-[3.98px] absolute bg-rose-700"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>




<!-- MAIL CONTENT -->
<div class="w-[1026px] h-[716px] px-3 py-6 bg-neutral-800 rounded-tl rounded-tr-[48px] rounded-bl rounded-br-3xl inline-flex flex-col justify-start items-start gap-6 overflow-hidden">
    <div class="self-stretch inline-flex justify-between items-center">
        <div class="self-stretch flex justify-start items-center gap-6">
            <div class="justify-center text-white text-2xl font-bold font-['Google_Sans_Flex'] leading-6 tracking-wide">Email title</div>
        </div>
        <div class="self-stretch flex justify-start items-center gap-6">
            <div class="inline-flex flex-col justify-start items-start">
                <div class="px-12 py-3 relative bg-rose-700 rounded-full inline-flex justify-start items-center gap-3">
                    <div class="w-44 h-12 left-0 top-0 absolute bg-white/0 rounded-[48px] shadow-[0px_4px_6px_-4px_rgba(0,0,0,0.10)] shadow-lg"></div>
                    <div class="inline-flex flex-col justify-start items-center">
                        <div class="text-center justify-center text-white text-base font-bold font-['Plus_Jakarta_Sans'] leading-6">Reply</div>
                    </div>
                    <div class="h-3.5 inline-flex flex-col justify-start items-center">
                        <div class="w-4 flex-1 bg-white"></div>
                    </div>
                </div>
            </div>
            <div class="w-12 self-stretch p-3 bg-zinc-500 rounded-[48px] flex justify-center items-center gap-2.5 overflow-hidden">
                <div class="w-6 self-stretch p-1 rounded-full flex justify-center items-center overflow-hidden">
                    <div class="w-3.5 h-3.5 bg-black"></div>
                </div>
            </div>
        </div>
    </div>
    <div class="self-stretch inline-flex justify-start items-start gap-3">
        <div class="h-20 p-3 bg-zinc-800 rounded-[48px] flex justify-start items-center gap-2.5 overflow-hidden">
            <div class="w-14 self-stretch p-2 rounded-full flex justify-center items-center overflow-hidden">
                <div class="w-6 self-stretch bg-zinc-500"></div>
            </div>
        </div>
        <div class="flex-1 rounded-3xl flex justify-start items-start gap-1">
            <div class="self-stretch p-7 bg-zinc-800 rounded-tl-[48px] rounded-tr rounded-bl-[48px] rounded-br inline-flex flex-col justify-center items-start gap-1">
                <div class="self-stretch justify-center text-stone-200 text-xl font-semibold font-['Google_Sans_Flex'] leading-6 tracking-wide line-clamp-1">Username</div>
            </div>
            <div class="flex-1 self-stretch px-6 py-7 bg-zinc-800 rounded-tl rounded-tr-[48px] rounded-bl rounded-br-[48px] inline-flex flex-col justify-center items-start gap-1">
                <div class="self-stretch justify-center text-stone-400 text-sm font-medium font-['Google_Sans_Flex'] leading-6 tracking-wide line-clamp-1">username@email.com</div>
            </div>
        </div>
    </div>
    <div class="self-stretch flex-1 p-6 bg-zinc-800 rounded-3xl flex flex-col justify-start items-start gap-1">
        <div class="self-stretch justify-center text-stone-400 text-sm font-medium font-['Google_Sans_Flex'] leading-6 tracking-wide line-clamp-1">Email content</div>
    </div>
</div>





<!-- COMPOSE EMAIL -->
<div class="w-[1026px] h-[716px] px-3 py-6 bg-neutral-800 rounded-tl rounded-tr-[48px] rounded-bl rounded-br-3xl inline-flex flex-col justify-start items-start gap-6 overflow-hidden">
    <div class="self-stretch inline-flex justify-between items-center">
        <div class="justify-center text-white text-2xl font-bold font-['Google_Sans_Flex'] leading-6 tracking-wide">New Draft</div>
        <div class="inline-flex flex-col justify-start items-start">
            <div class="px-12 py-3 relative bg-rose-700 rounded-full inline-flex justify-start items-center gap-3">
                <div class="w-40 h-12 left-0 top-0 absolute bg-white/0 rounded-[48px] shadow-[0px_4px_6px_-4px_rgba(0,0,0,0.10)] shadow-lg"></div>
                <div class="inline-flex flex-col justify-start items-center">
                    <div class="text-center justify-center text-white text-base font-bold font-['Plus_Jakarta_Sans'] leading-6">Send</div>
                </div>
                <div class="inline-flex flex-col justify-start items-center">
                    <div class="w-4 h-3.5 bg-white"></div>
                </div>
            </div>
        </div>
    </div>
    <div class="self-stretch flex flex-col justify-start items-start gap-3">
        <div class="self-stretch rounded-3xl inline-flex justify-start items-start gap-1">
            <div class="self-stretch px-9 py-7 bg-zinc-800 rounded-tl-[48px] rounded-tr rounded-bl-[48px] rounded-br flex justify-start items-center gap-2.5 overflow-hidden">
                <div class="justify-center text-stone-200 text-2xl font-bold font-['Google_Sans_Flex'] leading-6 tracking-wide line-clamp-1">To</div>
            </div>
            <div class="flex-1 self-stretch px-6 py-7 bg-zinc-800 rounded-tl rounded-tr-[48px] rounded-bl rounded-br-[48px] inline-flex flex-col justify-center items-start gap-1">
                <div class="self-stretch justify-center text-stone-400 text-sm font-medium font-['Google_Sans_Flex'] leading-6 tracking-wide line-clamp-1">Add recipients</div>
            </div>
        </div>
        <div class="self-stretch rounded-3xl inline-flex justify-start items-start gap-1">
            <div class="self-stretch px-9 py-7 bg-zinc-800 rounded-tl-[48px] rounded-tr rounded-bl-[48px] rounded-br flex justify-start items-center gap-2.5 overflow-hidden">
                <div class="justify-center text-stone-200 text-2xl font-bold font-['Google_Sans_Flex'] leading-6 tracking-wide line-clamp-1">Subject</div>
            </div>
            <div class="flex-1 self-stretch px-6 py-7 bg-zinc-800 rounded-tl rounded-tr-[48px] rounded-bl rounded-br-[48px] inline-flex flex-col justify-center items-start gap-1">
                <div class="self-stretch justify-center text-stone-400 text-sm font-medium font-['Google_Sans_Flex'] leading-6 tracking-wide line-clamp-1">The art of silence...</div>
            </div>
        </div>
    </div>
    <div class="self-stretch flex-1 p-6 bg-zinc-800 rounded-[48px] flex flex-col justify-between items-center">
        <div class="self-stretch justify-center text-stone-400 text-sm font-medium font-['Google_Sans_Flex'] leading-6 tracking-wide line-clamp-1">Write your message here...</div>
        <div class="px-9 py-6 bg-neutral-800 rounded-[48px] inline-flex justify-center items-center gap-9">
            <div class="w-3 self-stretch bg-stone-300"></div>
            <div class="w-3.5 self-stretch bg-stone-300"></div>
            <div class="w-3.5 self-stretch bg-stone-300"></div>
            <div class="w-3 self-stretch bg-stone-300"></div>
            <div class="w-px self-stretch bg-stone-300/50"></div>
            <div class="w-2.5 self-stretch bg-stone-300"></div>
            <div class="w-4 self-stretch bg-stone-300"></div>
            <div class="w-px self-stretch bg-stone-300/50"></div>
            <div class="w-8 h-4 bg-stone-300"></div>
        </div>
    </div>
</div>