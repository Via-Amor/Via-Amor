//
//  SearchViewModel.swift
//  Amor
//
//  Created by 홍정민 on 12/1/24.
//

import RxSwift
import RxCocoa

final class SearchViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let useCase: SpaceUseCase
    
    init(spaceUseCase: SpaceUseCase) {
        self.useCase = spaceUseCase
    }
    
    struct Input {
        let searchText: PublishSubject<String>
        let searchButtonTap: PublishRelay<Void>
        let section: PublishSubject<Int>
    }
    
    struct Output {
        let showEmptySearchText: PublishRelay<Void>
        let showSearchView: PublishRelay<Void>
        let showResultView: PublishRelay<Bool>
        let searchResult: BehaviorRelay<[SearchSectionModel]>
    }
    
    func transform(_ input: Input) -> Output {
        let searchText = PublishSubject<String>()
        let showEmptySearchText = PublishRelay<Void>()
        let showSearchView = PublishRelay<Void>()
        let showResultView = PublishRelay<Bool>()
        let searchResult = BehaviorRelay<[SearchSectionModel]>(value: [])
        
        input.searchButtonTap
            .withLatestFrom(input.searchText)
            .map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            .bind(with: self) { owner, text in
                if text.isEmpty {
                    showEmptySearchText.accept(())
                } else {
                    searchText.onNext(text)
                }
            }
            .disposed(by: disposeBag)
        
        
        searchText
            .map {
                (SpaceRequestDTO(workspace_id: UserDefaultsStorage.spaceId), SearchRequestDTO(keyword: $0))
            }
            .flatMap { request in
                let (request, query) = request
                return self.useCase.searchInSpace(request: request, query: query)
            }
            .bind(with: self) { owner, result in
                switch result {
                case .success(let success):
                    let channels = SearchSectionModel(
                        section: 0,
                        header: SearchSectionHeader.channel.rawValue,
                        isOpen: true,
                        items: success.channels.map {
                            SearchSectionItem.channelItem($0)
                        }
                    )
                    
                    let members = SearchSectionModel(
                        section: success.channels.isEmpty ? 0 : 1,
                        header: SearchSectionHeader.member.rawValue,
                        isOpen: true,
                        items: success.workspaceMembers.map {
                            SearchSectionItem.memberItem($0)
                        }
                    )
                    
                    let array: [SearchSectionModel]
                    
                    if channels.items.isEmpty {
                        array = [
                            members
                        ]
                    } else if members.items.isEmpty {
                        array = [
                            channels
                        ]
                    } else {
                        array = [
                            channels,
                            members
                        ]
                    }
                    
                    showResultView.accept(success.channels.isEmpty && success.workspaceMembers.isEmpty)
                    searchResult.accept(array)
                    
                case .failure(let error):
                    print(error)
                }
            }
            .disposed(by: disposeBag)
        
        return Output(showEmptySearchText: showEmptySearchText, showSearchView: showSearchView, showResultView: showResultView, searchResult: searchResult)
    }
}

extension SearchViewModel {
    enum SearchSectionHeader: String {
        case channel = "채널"
        case member = "멤버"
    }
}
