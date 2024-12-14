//
//  ChatViewModel.swift
//  Amor
//
//  Created by 김상규 on 11/24/24.
//

import UIKit
import RxSwift
import RxCocoa

final class ChatViewModel: BaseViewModel {
    let chatType: ChatType
    let useCase: ChatUseCase
    private var channelID: String = ""
    private var roomID: String = ""
    
    private let disposeBag = DisposeBag()
    
    struct Input {
        let viewWillAppearTrigger: Observable<Void>
        let viewWillDisappearTrigger: Observable<Void>
        let sendButtonTap: ControlEvent<Void>
        let chatText: ControlProperty<String>
        let chatImage: BehaviorRelay<[UIImage]>
        let chatImageName: BehaviorRelay<[String]>
    }
    
    struct Output {
        let navigationContent: Driver<ChatType>
        let presentChatList: Driver<[Chat]>
        let presentErrorToast: Signal<String>
        let clearChatText: Signal<Void>
        let initScrollToBottom: Signal<Int>
        let scrollToBottom: Signal<Int>
    }
    
    init(chatType: ChatType, useCase: ChatUseCase) {
        self.chatType = chatType
        self.useCase = useCase
    }
    
    func transform(_ input: Input) -> Output {
        let navigationContent = BehaviorRelay(value: chatType)
        let connectSocket = PublishRelay<Void>()
        let presentChatList = BehaviorRelay<[Chat]>(value: [])
        let presentErrorToast = PublishRelay<String>()
        let clearChatText = PublishRelay<Void>()
        let initScrollToBottom = PublishRelay<Int>()
        let scrollToBottom = PublishRelay<Int>()
        
        let fetchChannelChat = PublishRelay<Void>()
        let fetchDMChat = PublishRelay<Void>()
        
        // 소켓 연결 처리
        connectSocket
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.useCase.observeSocketChat(chatType: owner.chatType)
            }
            .bind(with: self) { owner, chatList in
                presentChatList.accept(chatList)
                scrollToBottom.accept(chatList.count)
            }
            .disposed(by: disposeBag)
        
        // 채널 채팅 조회
        fetchChannelChat
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.useCase.fetchChannelChatList(channelID: owner.channelID)
            }
            .bind(with: self) { owner, persistChatList in
                presentChatList.accept(persistChatList)
                initScrollToBottom.accept(persistChatList.count)
                connectSocket.accept(())
            }
            .disposed(by: disposeBag)
        
        // DM 채팅 조회
        fetchDMChat
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.useCase.fetchDMChatList(roomID: owner.roomID)
            }
            .bind(with: self) { owner, persistChatList in
                presentChatList.accept(persistChatList)
                initScrollToBottom.accept(persistChatList.count)
                connectSocket.accept(())
            }
            .disposed(by: disposeBag)
        
        input.sendButtonTap
            .withLatestFrom(
                Observable.combineLatest(
                    input.chatText,
                    input.chatImage,
                    input.chatImageName
                )
            )
            .filter { value in
                let (text, image, _) = value
                return !text.isEmpty || !image.isEmpty
            }
            .withUnretained(self)
            .map { _, value in
                let (text, image, imageNames) = value
                let request: ChatRequest
                
                switch self.chatType {
                case .channel(let channel):
                    request = ChatRequest(
                        workspaceId: UserDefaultsStorage.spaceId,
                        id: channel.channel_id,
                        cursor_date: ""
                    )
                case .dm(let dMRoom):
                    request = ChatRequest(
                        workspaceId: UserDefaultsStorage.spaceId,
                        id: dMRoom?.room_id ?? "",
                        cursor_date: ""
                    )
                }
                
                let requestBody = ChatRequestBody(
                    content: text,
                    files: image.map {
                        $0.jpegData(compressionQuality: 0.5) ?? Data()
                    },
                    fileNames: imageNames
                )
                
                return (request, requestBody)
            }
            .flatMap { value in
                let (request, body) = value
                switch self.chatType {
                case .channel:
                    return self.useCase.postServerChannelChat(
                        request: request,
                        body: body
                    )
                case .dm:
                    return self.useCase.postServerDMChat(
                        request: request,
                        body: body
                    )
                }
            }
            .subscribe(with: self) { owner, result in
                switch result {
                case .success:
                    print("채팅 전송 ✅")
                    clearChatText.accept(())
                case .failure(let error):
                    print("채팅 전송 오류 ❌", error)
                    presentErrorToast.accept(ToastText.postChatError)
                }
            }
            .disposed(by: disposeBag)
        
        input.viewWillAppearTrigger
            .withUnretained(self)
            .bind(with: self) { owner, _ in
                switch owner.chatType {
                case .channel(let channel):
                    owner.channelID = channel.channel_id
                    fetchChannelChat.accept(())
                case .dm(let dMRoomInfo):
                    owner.roomID = dMRoomInfo?.room_id ?? ""
                    fetchDMChat.accept(())
                }
            }
            .disposed(by: disposeBag)
        
        input.viewWillDisappearTrigger
            .bind(with: self) { owner, _ in
                owner.useCase.closeSocketConnection()
            }
            .disposed(by: disposeBag)
        
        return Output(
            navigationContent: navigationContent.asDriver(),
            presentChatList: presentChatList.asDriver(),
            presentErrorToast: presentErrorToast.asSignal(),
            clearChatText: clearChatText.asSignal(),
            initScrollToBottom: initScrollToBottom.asSignal(),
            scrollToBottom: scrollToBottom.asSignal()
        )
    }
}
